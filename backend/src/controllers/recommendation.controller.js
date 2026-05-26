import axios from "axios";
import { asyncHandler } from "../middlewares/async.middleware.js";
import { db as prisma } from "../config/db.js";
import { getAllSchoolsWithRecommendationData } from "../services/school.service.js";

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
  const result = await getAllSchoolsWithRecommendationData({
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

export const updateInteractionResult = asyncHandler(async (req, res) => {
  const { recommendationId, schoolId } = req.params;
  const { result } = req.body;

  const updated = await prisma.recommendedSchool.updateMany({
    where: {
      recommendationId: Number(recommendationId),
      schoolId: Number(schoolId),
    },

    data: {
      interactionResult: result,
    },
  });

  console.log(`Interaction upgraded to ${result}`);

  res.json({
    message: "Interaction result updated",
    data: updated,
  });
});

// ---------------------------------------------------------------------------
// Recommendation feedback
// ---------------------------------------------------------------------------

export const feedback = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const { result, schoolId } = req.body;

  // Interaction strength ranking
  const PRIORITY = {
    IGNORED: 0,
    OPENED: 1,
    FAVORITED: 2,
  };

  // STEP 1
  // Fetch existing history
  const existingHistory = await prisma.recommendationHistory.findUnique({
    where: {
      id: Number(id),
    },
  });

  if (!existingHistory) {
    return res.status(404).json({
      success: false,
      message: "Recommendation history not found",
    });
  }

  // STEP 2
  // Determine if update is allowed
  const currentPriority = PRIORITY[existingHistory.interactionResult] ?? 0;

  const incomingPriority = PRIORITY[result] ?? 0;

  let history = existingHistory;

  // Only upgrade interaction strength
  if (incomingPriority > currentPriority) {
    history = await prisma.recommendationHistory.update({
      where: {
        id: Number(id),
      },

      data: {
        interactionResult: result,
      },
    });

    console.log(
      `Interaction upgraded: ${existingHistory.interactionResult} -> ${result}`,
    );
  } else {
    console.log(`Ignored weaker interaction: ${result}`);
  }

  // STEP 3
  // Send feedback to ML service
  try {
    await axios.post(
      `${process.env.ML_SERVICE_URL}/feedback`,
      {
        recommendation_id: Number(id),

        result: result.toLowerCase(),

        school_id: Number(schoolId),

        parent_id: history.parentId,
      },
      {
        timeout: 10000,
      },
    );

    console.log("✅ ML feedback sent");
  } catch (err) {
    console.error("❌ ML feedback error:", err.response?.data || err.message);

    // Do NOT fail user request
    // recommendation system should remain resilient
  }

  return res.json({
    success: true,
    interactionResult: history.interactionResult,
  });
});
