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
  if (!userId) return { parent: null, preference: null };

  const [parent, preference] = await Promise.all([
    prisma.parent.findUnique({ where: { userId } }),
    prisma.preference.findUnique({ where: { parentId: userId } }),
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

  // Parse ?near=lat,lng override so callers can override the parent's home-pin.
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
  schools, // Full school objects from Prisma
  query = {},
  userId = null,
) {
  const ctx = await loadParentContext(userId);
  const criteria = resolveCriteria(query, ctx);

  // Transform the schools array to match the Python Pydantic model.
  // Prisma returns camelCase fields; Python expects snake_case.
  const schoolsForAI = schools.map((school) => ({
    id: school.id,
    name: school.schoolName,
    curriculum: school.curriculum.toLowerCase(),
    tuition_fee: Number(school.tuitionFee),
    rating: Number(school.rating),
    latitude: Number(school.latitude),
    longitude: Number(school.longitude),
    facilities: school.facilities || "",
    verification_status: school.verificationStatus.toLowerCase(),
    school_level: school.schoolLevel
      ? school.schoolLevel.toLowerCase()
      : "primary",
  }));

  try {
    // STEP 1 — Ask Python ML Service
    const response = await axios.post(`${ML_SERVICE_URL}/recommend`, {
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
    });

    const rankedFromAI = response.data.ranked;

    // STEP 2 — HYDRATION: Map AI results back to full Prisma objects so
    // Flutter's School.fromJson(json) gets every field it needs.
    const finalRankedResults = rankedFromAI
      .map((rankItem) => {
        const aiId = rankItem.school_id || rankItem.id;

        const originalSchool = schools.find(
          (s) => String(s.id) === String(aiId),
        );

        if (!originalSchool) {
          console.warn(`Could not find school in DB with ID: ${aiId}`);
          return null;
        }

        // Spread gives us Prisma camelCase fields (schoolName, tuitionFee,
        // verificationStatus, …) which is exactly what Flutter expects.
        return {
          ...originalSchool,
          score: rankItem.score,
          breakdown: rankItem.breakdown || {},
        };
      })
      .filter(Boolean);

    // STEP 3 — Save Recommendation History (best-effort; don't break the
    // response if the history write fails).
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
      } catch (histErr) {
        console.error("Failed to save recommendation history:", histErr.message);
      }
    }

    return {
      ranked: finalRankedResults,
      criteria,
      historyId,
    };
  } catch (err) {
    console.error("AI Service Error:", err.message);
    return fallbackRecommendationSystem(schools, criteria);
  }
}

// ---------------------------------------------------------------------------
// Fallback — simple weighted scoring when the Python service is unreachable
// ---------------------------------------------------------------------------

function fallbackRecommendationSystem(schools, criteria) {
  const ranked = schools.map((school) => {
    let score = 0;

    // Curriculum match (25%)
    if (
      school.curriculum &&
      school.curriculum.toLowerCase() === criteria.curriculum.toLowerCase()
    ) {
      score += 25;
    }

    // Budget fit (25%)
    const fee = Number(school.tuitionFee);
    if (fee >= criteria.minBudget && fee <= criteria.maxBudget) {
      score += 25;
    } else if (criteria.maxBudget > 0) {
      const diff = Math.min(
        Math.abs(fee - criteria.minBudget),
        Math.abs(fee - criteria.maxBudget),
      );
      score += Math.max(0, 25 * (1 - diff / criteria.maxBudget));
    }

    // Rating (20%)
    const rating = Number(school.rating);
    score += (rating / 5) * 20;

    // Verification bonus (10%)
    if (school.verificationStatus === "VERIFIED") {
      score += 10;
    } else {
      score += 4;
    }

    return {
      ...school,
      score: Math.round(score * 100) / 100,
      breakdown: {
        curriculum:
          school.curriculum?.toLowerCase() === criteria.curriculum.toLowerCase()
            ? 1
            : 0,
        budget:
          fee >= criteria.minBudget && fee <= criteria.maxBudget
            ? 1
            : Math.max(
                0,
                1 -
                  Math.min(
                    Math.abs(fee - criteria.minBudget),
                    Math.abs(fee - criteria.maxBudget),
                  ) /
                    (criteria.maxBudget || 1),
              ),
        rating: rating / 5,
        verification: school.verificationStatus === "VERIFIED" ? 1 : 0.4,
      },
    };
  });

  ranked.sort((a, b) => b.score - a.score);

  return { ranked, criteria, historyId: null };
}
