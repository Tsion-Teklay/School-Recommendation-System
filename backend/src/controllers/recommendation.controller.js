import { asyncHandler } from "../middlewares/async.middleware.js";
import { getAllSchools } from "../services/school.service.js";
import { getRecommendations } from "../services/recommendation.service.js";

/**
 * Phase 6 — return content-based ranked recommendations for the calling
 * parent. Uses their stored Preference + Parent profile (if any), with
 * query-string overrides for one-off searches.
 *
 * We always fetch a 50-school candidate pool here regardless of any `?limit=`
 * the caller passed: re-ranking is cheap and we want the parent to see the
 * best options after scoring, not the first N by insertion order. NOTE: the
 * `?limit=` from `paginationQuery` defaults to 10 inside Zod, so a naive
 * `req.query.limit ?? 50` fallback would never fire (`??` only catches
 * null/undefined, not the Zod-defaulted 10). Hardcoding the candidate-pool
 * size avoids that footgun.
 */
const RECOMMENDATION_CANDIDATE_POOL = 50;

export const recommend = asyncHandler(async (req, res) => {
  const result = await getAllSchools({
    ...req.query,
    limit: RECOMMENDATION_CANDIDATE_POOL,
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
