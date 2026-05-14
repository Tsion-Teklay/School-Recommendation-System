import axios from "axios";
import prisma from "../config/prisma.js";

const ML_SERVICE_URL = process.env.ML_SERVICE_URL;

export async function getRecommendations(
  schools, // These come from your DB via Prisma
  query = {},
  userId = null
) {
  const ctx = await loadParentContext(userId);
  const criteria = resolveCriteria(query, ctx);

  // FIX 1: Transform the schools array to match the Python Pydantic model
  const schoolsForAI = schools.map((school) => ({
    id: school.id,
    name: school.schoolName, // Mapping schoolName -> name
    curriculum: school.curriculum.toLowerCase(), // Enum -> lowercase string
    tuition_fee: Number(school.tuitionFee), // Decimal -> Number
    rating: Number(school.rating), // Decimal -> Number
    latitude: Number(school.latitude), // Decimal -> Number
    longitude: Number(school.longitude), // Decimal -> Number
    facilities: school.facilities || "", // Handle nulls
    verification_status: school.verificationStatus.toLowerCase(),
    school_level: school.schoolLevel ? school.schoolLevel.toLowerCase() : "primary",
  }));

  try {
    // STEP 1 — Ask Python ML Service
    const response = await axios.post(`${ML_SERVICE_URL}/recommend`, {
      parent_id: userId,
      preferences: {
        // FIX 2: Ensure preferences are numbers/lowercase too
        curriculum: criteria.curriculum.toLowerCase(),
        min_budget: Number(criteria.minBudget),
        max_budget: Number(criteria.maxBudget),
        distance_km: Number(criteria.distance),
        lat: Number(criteria.lat),
        lng: Number(criteria.lng),
      },
      schools: schoolsForAI, // Send the cleaned data
    });

    // STEP 2 — Extract Ranked Results
    const ranked = response.data.ranked;

    // STEP 3 — Save Recommendation History
    const history = await prisma.recommendationHistory.create({
      data: {
        parentId: userId,
        interactionResult: "IGNORED",
        recommendedSchools: {
          create: ranked.map((school) => ({
            // FIX 3: Ensure this matches your Python response key
            // (usually school_id if you mapped it that way in Python)
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
      ranked,
      criteria,
      historyId: history.id,
    };
  } catch (err) {
    console.error("AI Service Error:", err.message);

    // Fallback logic
    return fallbackRecommendationSystem(schools, criteria);
  }
}