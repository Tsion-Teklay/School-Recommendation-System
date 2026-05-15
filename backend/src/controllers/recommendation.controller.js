import axios from "axios";
import { asyncHandler } from "../middlewares/async.middleware.js";
import { db as prisma } from "../config/db.js";
import { getAllSchools } from "../services/school.service.js";
import { getRecommendations } from "../services/recommendation.service.js";

/**
 * We always fetch a 50-school candidate pool from page 1.
 * The ML service handles the ranking.
 */
const RECOMMENDATION_CANDIDATE_POOL = 50;

// ---------------------------------------------------------------------------
// Generate recommendations
// ---------------------------------------------------------------------------

export const recommend = asyncHandler(async (req, res) => {
  // Prevent browser caching during development/testing
  res.set("Cache-Control", "no-store");

  // Fetch candidate pool
  const result = await getAllSchools({
    ...req.query,
    page: 1,
    limit: RECOMMENDATION_CANDIDATE_POOL,
  });

  // ML-powered recommendation generation
  const recommendationResult = await getRecommendations(
    result.data,
    req.query,
    req.user?.id,
  );

  const { ranked, criteria, historyId, source } = recommendationResult;

  console.log("✅ Recommendation source:", source);

  return res.json({
    message: "Recommendations generated",

    source,

    historyId,

    data: ranked,

    criteria,

    meta: {
      total: ranked.length,

      page: 1,

      limit: ranked.length,

      totalPages: 1,
    },
  });
});

// ---------------------------------------------------------------------------
// Recommendation feedback
// ---------------------------------------------------------------------------

export const feedback = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const { result, schoolId } = req.body;

  // Update interaction result in DB
  const history = await prisma.recommendationHistory.update({
    where: {
      id: Number(id),
    },

    data: {
      interactionResult: result,
    },
  });

  // Send feedback to ML service
  try {
    await axios.post(
      `${process.env.ML_SERVICE_URL}/feedback`,
      {
        recommendation_id: id,

        result,

        school_id: schoolId,

        parent_id: history.parentId,
      },
      {
        timeout: 10000,
      },
    );

    console.log("✅ ML feedback sent");
  } catch (err) {
    console.error("❌ Failed to send ML feedback:", {
      message: err.message,
      status: err.response?.status,
    });

    // Optional:
    // throw new Error("ML feedback service unavailable");
  }

  return res.json({
    success: true,
  });
});
