import axios from "axios";
import { db as prisma } from "../config/db.js";

import { batchCalculateSchoolAnalytics } from "./analytics.service.js";

const ML_SERVICE_URL = process.env.ML_SERVICE_URL;

// Simple in-memory cache for analytics (consider Redis for production)
const analyticsCache = new Map();
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes

function getCachedAnalytics(schoolIds) {
  const now = Date.now();
  const cached = {};
  const missingIds = [];

  for (const id of schoolIds) {
    const cachedData = analyticsCache.get(id);
    if (cachedData && now - cachedData.timestamp < CACHE_TTL) {
      cached[id] = cachedData.data;
    } else {
      missingIds.push(id);
    }
  }

  return { cached, missingIds };
}

function setCachedAnalytics(data) {
  const now = Date.now();
  for (const [id, value] of Object.entries(data)) {
    analyticsCache.set(id, { data: value, timestamp: now });
  }
}

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
    schoolType: query.schoolType || pref?.schoolType || null,
    schoolLevel: query.schoolLevel || pref?.schoolLevel || null,
    lat: Number(nearLat ?? parent?.latitude ?? 9.02),
    lng: Number(nearLng ?? parent?.longitude ?? 38.75),
  };
}

// ---------------------------------------------------------------------------
// Main recommendation flow
// ---------------------------------------------------------------------------

export async function getRecommendations(schools, query = {}, userId = null) {
  const ctx = await loadParentContext(userId);

  const criteria = resolveCriteria(query, ctx);

  if (!ML_SERVICE_URL) {
    throw new Error("ML_SERVICE_URL is not configured");
  }

  // Transform Prisma school objects into Python-friendly payload with comprehensive metrics
  const schoolsForAI = schools.map((school) => {
    // Extract latest demographics
    const latestDemographics = school.demographics?.[0] || null;

    // Calculate achievement score from approved achievements
    const achievementScore =
      school.achievements?.reduce((sum, a) => sum + (a.score || 0), 0) || 0;
    const achievementCount = school.achievements?.length || 0;
    const recentAchievementYear = school.achievements?.[0]?.year || null;

    // Calculate gender balance index from demographics
    let genderBalanceIndex = 0;
    if (latestDemographics && latestDemographics.totalStudents > 0) {
      const girlsRatio =
        latestDemographics.girlsCount / latestDemographics.totalStudents;
      const boysRatio =
        latestDemographics.boysCount / latestDemographics.totalStudents;
      genderBalanceIndex = Math.max(0, 1 - Math.abs(girlsRatio - boysRatio));
    }

    // Calculate staff quality score from staff breakdown
    let staffQualityScore = 0;
    if (school.staffBreakdown && school.staffBreakdown.length > 0) {
      const phdCount =
        school.staffBreakdown.find((s) => s.educationLevel === "PHD")?.count ||
        0;
      const mastersCount =
        school.staffBreakdown.find((s) => s.educationLevel === "MASTERS")
          ?.count || 0;
      const degreeCount =
        school.staffBreakdown.find((s) => s.educationLevel === "DEGREE")
          ?.count || 0;
      const totalStaff = school.staffBreakdown.reduce(
        (sum, s) => sum + s.count,
        0,
      );

      if (totalStaff > 0) {
        // Weight higher education levels more
        staffQualityScore =
          (phdCount * 4 + mastersCount * 3 + degreeCount * 2) /
          (totalStaff * 4);
      }
    }

    return {
      id: school.id,
      name: school.schoolName,
      curriculum: school.curriculum ? school.curriculum.toLowerCase() : "local",
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
      school_type: school.schoolType ? school.schoolType.toLowerCase() : null,
      passing_rate: Number(
        latestDemographics?.passingRate || school.passingRate || 0,
      ),
      national_exam_score: Number(
        latestDemographics?.nationalExamScore || school.nationalExamScore || 0,
      ),

      total_students: Number(latestDemographics?.totalStudents || 0),
      girls_count: Number(latestDemographics?.girlsCount || 0),
      boys_count: Number(latestDemographics?.boysCount || 0),
      gender_balance_index: Number(genderBalanceIndex),
      academic_year: latestDemographics?.academicYear || null,

      achievement_score: Number(achievementScore),
      achievement_count: Number(achievementCount),
      recent_achievement_year: recentAchievementYear,

      staff_quality_score: Number(staffQualityScore),
      staff_breakdown: school.staffBreakdown || [],

      // Engagement metrics
      follower_count: Number(school._count?.subscribers || 0),
      review_count: Number(school._count?.reviews || 0),

      // School-level metrics
      total_achievement_score: Number(school.achievementScore || 0),
    };
  });

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
          school_type: criteria.schoolType
            ? criteria.schoolType.toLowerCase()
            : null,
          school_level: criteria.schoolLevel
            ? criteria.schoolLevel.toLowerCase()
            : null,
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

    console.log(`✅ ML service returned ${rankedFromAI.length} ranked schools`);

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
          console.warn(`⚠️ Could not find matching school for AI ID: ${aiId}`);

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
                features: r.features,
                interactionResult: "IGNORED",
              })),
            },

            preferenceCriteria: {
              create: [
                {
                  minBudget: criteria.minBudget,
                  maxBudget: criteria.maxBudget,
                  curriculum: criteria.curriculum,
                  distance: criteria.distance,
                  schoolType: criteria.schoolType || null,
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

    throw new Error(`Recommendation ML service unavailable: ${err.message}`);
  }
}
