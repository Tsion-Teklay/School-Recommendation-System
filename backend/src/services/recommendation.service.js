import axios from "axios";
import { db as prisma } from "../config/db.js";

const ML_SERVICE_URL = process.env.ML_SERVICE_URL;

export async function getRecommendations(
  schools, // Full school objects from Prisma
  query = {},
  userId = null,
) {
  const ctx = await loadParentContext(userId);
  const criteria = resolveCriteria(query, ctx);

  // Transform the schools array to match the Python Pydantic model
  const schoolsForAI = schools.map((school) => ({
    id: school.id,
    schoolName: school.school_name,
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
        min_budget: Number(criteria.minBudget),
        max_budget: Number(criteria.maxBudget),
        distance_km: Number(criteria.distance),
        lat: Number(criteria.lat),
        lng: Number(criteria.lng),
      },
      schools: schoolsForAI,
    });

    const rankedFromAI = response.data.ranked;

    // STEP 2 — HYDRATION: Map AI results back to full Prisma objects
    // This ensures Flutter's School.fromJson(json) gets the fields it needs
    // Inside the try block after const rankedFromAI = response.data.ranked;

    const finalRankedResults = rankedFromAI
      .map((rankItem) => {
        // 1. MUST use school_id because that is what your AI JSON shows
        const aiId = rankItem.school_id || rankItem.id;

        // 2. Use String coercion to ensure '1' matches 1
        const originalSchool = schools.find(
          (s) => String(s.id) === String(aiId),
        );

        if (!originalSchool) {
          console.warn(`Could not find school in DB with ID: ${aiId}`);
          return null;
        }

        // 3. Combine them for the Flutter Frontend
        return {
          ...originalSchool,
          // Add these specifically for the Recommendation DTO in Flutter
          schoolName: originalSchool.school_name, // Map snake_case to camelCase
          score: rankItem.score,
          breakdown: rankItem.breakdown || {},
        };
      })
      .filter(Boolean); // Remove any nulls if a school wasn't found

    return {
      ranked: finalRankedResults,
      criteria,
      historyId: history.id,
    };

    // STEP 3 — Save Recommendation History
    const history = await prisma.recommendationHistory.create({
      data: {
        parentId: userId,
        interactionResult: "IGNORED",
        recommendedSchools: {
          create: rankedFromAI.map((school) => ({
            schoolId: school.id || school.school_id,
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

    return {
      ranked: finalRankedResults, // Send the full objects, not just AI scores
      criteria,
      historyId: history.id,
    };
  } catch (err) {
    console.error("AI Service Error:", err.message);
    return fallbackRecommendationSystem(schools, criteria);
  }
}
