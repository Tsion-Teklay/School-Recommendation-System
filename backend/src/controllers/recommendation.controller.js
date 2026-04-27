import { asyncHandler } from "../middlewares/async.middleware.js";
import { getAllSchools } from "../services/school.service.js";
import { getRecommendations } from "../services/recommendation.service.js";

/**
 * Phase 6 — return content-based ranked recommendations for the calling
 * parent. Uses their stored Preference + Parent profile (if any), with
 * query-string overrides for one-off searches. Bumps the candidate set
 * size to 50 by default since re-ranking is cheap and we want the parent
 * to see the best options regardless of insertion order.
 */
export const recommend = asyncHandler(async (req, res) => {
  const result = await getAllSchools({
    ...req.query,
    limit: req.query.limit ?? 50,
  });

  const { ranked, criteria } = await getRecommendations(
    result.data,
    req.query,
    req.user?.id
  );

  res.json({
    message: "Recommendations generated",
    data: ranked,
    criteria,
    meta: result.meta,
  });
});
