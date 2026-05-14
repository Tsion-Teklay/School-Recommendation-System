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


  // Don't forward `result.meta` directly: it carries the pagination shape of
  // the *internal* candidate-pool query (e.g. `{ total: 200, totalPages: 4 }`
  // when the filters match more schools than the pool size). The caller would
  // see `totalPages > 1` and assume `?page=2` returns the next slice — but the
  // controller pins page=1, so paginating the recommendations endpoint is a
  // no-op. Surface a meta object that describes what we actually returned.
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

export async function feedback(req, res) {
  const { id } = req.params;

  const { result, schoolId } = req.body;

  const history =
    await prisma.recommendationHistory.update({
      where: {
        id: Number(id)
      },
      data: {
        interactionResult: result
      }
    });

  await axios.post(
    `${process.env.ML_SERVICE_URL}/feedback`,
    {
      recommendation_id: id,
      result,
      school_id: schoolId,
      parent_id: history.parentId
    }
  );

  return res.json({
    success: true
  });
}
