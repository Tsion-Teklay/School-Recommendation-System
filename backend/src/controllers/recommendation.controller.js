import axios from "axios";
import { asyncHandler } from "../middlewares/async.middleware.js";
import { db as prisma } from "../config/db.js";
import { getAllSchools } from "../services/school.service.js";
import { getRecommendations } from "../services/recommendation.service.js";

/**
 * Phase 6 — return content-based ranked recommendations for the calling
 * parent. Uses their stored Preference + Parent profile (if any), with
 * query-string overrides for one-off searches.
 *
 * We always fetch a 50-school candidate pool from page 1 here, regardless of
 * any `?limit=` or `?page=` the caller passed: re-ranking is cheap and we
 * want the parent to see the best options after scoring, not the first N by
 * insertion order.
 */
const RECOMMENDATION_CANDIDATE_POOL = 50;

export const recommend = asyncHandler(async (req, res) => {
  const result = await getAllSchools({
    ...req.query,
    page: 1,
    limit: RECOMMENDATION_CANDIDATE_POOL,
  });

  const recommendationResult = await getRecommendations(
    result.data,
    req.query,
    req.user?.id,
  );

  if (!recommendationResult) {
    return res
      .status(500)
      .json({ error: "Service failed to return results" });
  }

  const { ranked, criteria } = recommendationResult;

  res.json({
    message: "Recommendations generated",
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

export const feedback = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { result, schoolId } = req.body;

  const history = await prisma.recommendationHistory.update({
    where: {
      id: Number(id),
    },
    data: {
      interactionResult: result,
    },
  });

  await axios.post(`${process.env.ML_SERVICE_URL}/feedback`, {
    recommendation_id: id,
    result,
    school_id: schoolId,
    parent_id: history.parentId,
  });

  return res.json({
    success: true,
  });
});
