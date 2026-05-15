import axios from "axios";
import { db as prisma } from "../config/db.js";

const ML_SERVICE_URL = process.env.ML_SERVICE_URL;

// ---------------------------------------------------------------------------
// Context helpers
// ---------------------------------------------------------------------------

/**
 * Load the parent's stored profile (home-pin) and preference (budget,
 * curriculum, distance) so the recommender can use them as defaults.
 * Returns `null` fields when nothing has been saved yet.
 */
async function loadParentContext(userId) {
  if (!userId) {
    return {
      parent: null,
      preference: null,
    };
  }

  const [parent, preference] = await Promise.all([
    prisma.parent.findUnique({
      where: { userId },
    }),

    prisma.preference.findUnique({
      where: { parentId: userId },
    }),
  ]);

  return { parent, preference };
}

/**
 * Merge query-string overrides with the parent's stored preferences.
 * Falls back to sensible defaults when neither source has a value.
 */
function resolveCriteria(query, ctx) {
  const pref = ctx.preference;
  const parent = ctx.parent;

  // Parse ?near=lat,lng override
  let nearLat = null;
  let nearLng = null;

  if (query.near) {
    const [latStr, lngStr] = String(query.near).split(",");

    nearLat = Number(latStr);
    nearLng = Number(lngStr);

    if (Number.isNaN(nearLat) || Number.isNaN(nearLng)) {
      nearLat = null;
      nearLng = null;
    }
  }

  return {
    curriculum: query.curriculum || pref?.curriculum || "LOCAL",

    minBudget: Number(query.minFee ?? pref?.minBudget ?? 0),

    maxBudget: Number(query.maxFee ?? pref?.maxBudget ?? 100000),

    distance: Number(query.radiusKm ?? pref?.distance ?? 25),

    lat: Number(nearLat ?? parent?.latitude ?? 9.02),

    lng: Number(nearLng ?? parent?.longitude ?? 38.75),
  };
}

// ---------------------------------------------------------------------------
// Main recommendation flow
// ---------------------------------------------------------------------------

export async function getRecommendations(
  schools,
  query = {},
  userId = null,
) {
  const ctx = await loadParentContext(userId);

  const criteria = resolveCriteria(query, ctx);

  if (!ML_SERVICE_URL) {
    throw new Error("ML_SERVICE_URL is not configured");
  }

  // Transform Prisma school objects into Python-friendly payload
  const schoolsForAI = schools.map((school) => ({
    id: school.id,

    name: school.schoolName,

    curriculum: school.curriculum
      ? school.curriculum.toLowerCase()
      : "local",

    tuition_fee: Number(school.tuitionFee),

    rating: Number(school.rating || 0),

    latitude: Number(school.latitude),

    longitude: Number(school.longitude),

    facilities: school.facilities || "",

    verification_status: school.verificationStatus
      ? school.verificationStatus.toLowerCase()
      : "pending",

    school_level: school.schoolLevel
      ? school.schoolLevel.toLowerCase()
      : "primary",
  }));

  try {
    console.log("🚀 Sending schools to ML service...");

    const response = await axios.post(
      `${ML_SERVICE_URL}/recommend`,
      {
        parent_id: userId,

        preferences: {
          curriculum: criteria.curriculum.toLowerCase(),

          min_budget: criteria.minBudget,

          max_budget: criteria.maxBudget,

          distance_km: criteria.distance,

          lat: criteria.lat,

          lng: criteria.lng,
        },

        schools: schoolsForAI,
      },
      {
        timeout: 10000, // 10 seconds
      },
    );

    const rankedFromAI = response.data?.ranked;

    if (!Array.isArray(rankedFromAI)) {
      throw new Error("Invalid ML response format");
    }

    console.log(
      `✅ ML service returned ${rankedFromAI.length} ranked schools`,
    );

    // Fast lookup map
    const schoolMap = new Map(
      schools.map((school) => [String(school.id), school]),
    );

    // Hydrate ML results back into full Prisma school objects
    const finalRankedResults = rankedFromAI
      .map((rankItem) => {
        const aiId = String(rankItem.school_id || rankItem.id);

        const originalSchool = schoolMap.get(aiId);

        if (!originalSchool) {
          console.warn(
            `⚠️ Could not find matching school for AI ID: ${aiId}`,
          );

          return null;
        }

        return {
          ...originalSchool,

          score: Number(rankItem.score || 0),

          breakdown: rankItem.breakdown || {},
        };
      })
      .filter(Boolean);

    // -----------------------------------------------------------------------
    // Save recommendation history
    // -----------------------------------------------------------------------

    let historyId = null;

    if (userId) {
      try {
        const history = await prisma.recommendationHistory.create({
          data: {
            parentId: userId,

            interactionResult: "IGNORED",

            recommendedSchools: {
              create: rankedFromAI.map((r) => ({
                schoolId: r.school_id || r.id,
              })),
            },

            preferenceCriteria: {
              create: [
                {
                  minBudget: criteria.minBudget,

                  maxBudget: criteria.maxBudget,

                  curriculum: criteria.curriculum,

                  distance: criteria.distance,
                },
              ],
            },
          },
        });

        historyId = history.id;
      } catch (historyErr) {
        console.error(
          "⚠️ Failed to save recommendation history:",
          historyErr.message,
        );
      }
    }

    return {
      ranked: finalRankedResults,

      criteria,

      historyId,

      source: "ml-service",
    };
  } catch (err) {
    console.error("❌ AI Service Error:", {
      message: err.message,
      status: err.response?.status,
      data: err.response?.data,
    });

    throw new Error(
      `Recommendation ML service unavailable: ${err.message}`,
    );
  }
}