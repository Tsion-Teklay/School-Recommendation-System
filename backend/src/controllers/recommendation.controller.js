import { asyncHandler } from "../middlewares/async.middleware.js";
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
 * insertion order. NOTE: the `?limit=` and `?page=` from `paginationQuery`
 * default to 10/1 inside Zod, so a naive `req.query.limit ?? 50` fallback
 * would never fire (`??` only catches null/undefined, not the Zod-defaulted
 * value). Pinning both candidate-pool size and page avoids that footgun and
 * also stops `?page=2` from silently shifting the candidate window past the
 * top schools.
 */
const RECOMMENDATION_CANDIDATE_POOL = 50;

export const recommend = asyncHandler(async (req, res) => {
  const result = await getAllSchools({
    ...req.query,
    page: 1,
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
