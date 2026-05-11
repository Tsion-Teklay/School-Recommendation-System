import { db } from "../config/db.js";

/**
 * Phase 6 — content-based recommender v1.
 *
 * Replaces the Phase 0 mock (+5 for curriculum match, +5 for budget proximity)
 * with a weighted score across six signals. Each component is normalized to
 * [0..1] before being multiplied by its weight, so the final score lives in
 * [0..100] regardless of how many signals are available.
 *
 * Why content-based rather than collaborative filtering?
 * The catalog is small (a few hundred schools at best) and the user base is
 * even smaller, so there isn't enough interaction history to learn from. The
 * spec calls for "AI-based" matching; weighted content-based scoring is the
 * defensible v1 — it produces explainable rankings (each row carries its
 * `breakdown`) and slot-replaces cleanly with a TF/Keras model in v2 if we
 * ever want one (just swap `scoreSchool`).
 *
 * Ranking signals + default weights (sum = 100):
 *   curriculum match      : 25  (binary)
 *   budget fit            : 20  (1 inside [min,max], linear decay outside)
 *   distance              : 20  (exponential decay around preferred radius)
 *   rating                : 15  (school.rating / 5)
 *   facilities            : 10  (saturating; 5+ facilities = full credit)
 *   verification status   : 10  (VERIFIED=1, PENDING=0.4, REJECTED=0)
 *
 * Inputs (in priority order):
 *   1. The parent's stored Preference + Parent.{lat,lng}, if present.
 *   2. Query overrides (`curriculum`, `minFee`, `maxFee`, `near`, `radiusKm`).
 *      These let the parent re-rank without rewriting their saved preferences.
 *   3. Sensible neutral defaults (no preference, no penalty) when neither is
 *      available — a brand-new parent with no profile still gets a usable
 *      ranking driven by rating + verification.
 */

export const RECOMMENDATION_WEIGHTS = Object.freeze({
  curriculum: 25,
  budget: 20,
  distance: 20,
  rating: 15,
  facilities: 10,
  verification: 10,
});

const EARTH_RADIUS_KM = 6371;
function toRad(deg) {
  return (deg * Math.PI) / 180;
}
function haversineKm(lat1, lng1, lat2, lng2) {
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * EARTH_RADIUS_KM * Math.asin(Math.sqrt(a));
}

/**
 * Look up the parent's stored profile + preference. Either may be missing
 * (parent never filled it out) — in that case we return null fields and the
 * scorer falls back to neutral defaults.
 */
export async function loadParentContext(userId) {
  if (!userId) return { parent: null, preference: null };
  const [parent, preference] = await Promise.all([
    db.parent.findUnique({ where: { userId } }),
    db.preference.findUnique({ where: { parentId: userId } }),
  ]);
  return { parent, preference };
}

/**
 * Resolve the criteria the recommender will actually score against.
 *
 * The query string overrides the parent profile when present (so a parent
 * can run a one-off "show me INTERNATIONAL within 5 km" search without
 * editing their saved preferences). When both are missing, the scorer
 * falls back to neutral.
 */
export function resolveCriteria(query = {}, ctx = {}) {
  const { parent, preference } = ctx;

  const curriculum = query.curriculum ?? preference?.curriculum ?? null;

  // Budget can come either from the saved Preference (minBudget/maxBudget)
  // or from explicit query overrides (minFee/maxFee). We treat them as the
  // same thing — what range of tuition fees the parent is willing to pay.
  const minBudget =
    query.minFee != null
      ? Number(query.minFee)
      : preference?.minBudget != null
      ? Number(preference.minBudget)
      : null;
  const maxBudget =
    query.maxFee != null
      ? Number(query.maxFee)
      : preference?.maxBudget != null
      ? Number(preference.maxBudget)
      : null;

  // Origin for distance scoring: explicit `near=lat,lng` (rare — we mostly
  // expect the parent profile lat/lng to drive this) wins over the parent
  // record.
  let lat = null;
  let lng = null;
  if (query.near) {
    const [latStr, lngStr] = String(query.near).split(",");
    const qLat = Number(latStr);
    const qLng = Number(lngStr);
    if (Number.isFinite(qLat) && Number.isFinite(qLng)) {
      lat = qLat;
      lng = qLng;
    }
  }
  if (lat == null && parent?.latitude != null && parent?.longitude != null) {
    lat = Number(parent.latitude);
    lng = Number(parent.longitude);
  }

  // Soft preferred radius (NOT a hard filter — that's what the
  // /api/schools?near= endpoint is for). Defaults to 25 km, matching
  // the Phase 4 proximity-search default.
  const preferredRadiusKm =
    query.radiusKm != null
      ? Number(query.radiusKm)
      : preference?.distance != null
      ? Number(preference.distance)
      : 25;

  return { curriculum, minBudget, maxBudget, lat, lng, preferredRadiusKm };
}

// --- score components: each returns [0..1] -----------------------------

function scoreCurriculum(school, criteria) {
  if (!criteria.curriculum) return 0.5; // neutral when no preference
  return school.curriculum === criteria.curriculum ? 1 : 0;
}

function scoreBudget(school, criteria) {
  const fee = Number(school.tuitionFee);
  if (!Number.isFinite(fee)) return 0;
  const { minBudget, maxBudget } = criteria;
  if (minBudget == null && maxBudget == null) return 0.5; // neutral

  // Inside the band → full credit.
  if (
    (minBudget == null || fee >= minBudget) &&
    (maxBudget == null || fee <= maxBudget)
  ) {
    return 1;
  }

  // Outside the band → linear decay over the band's width. With a 50k band
  // a fee 25k outside the upper bound scores 0.5; a fee 50k outside scores 0.
  const lo = minBudget ?? 0;
  const hi = maxBudget ?? Number.POSITIVE_INFINITY;
  const bandWidth =
    Number.isFinite(hi) && hi > lo ? hi - lo : Math.max(1000, lo);
  const distOutside = fee < lo ? lo - fee : fee - hi;
  return Math.max(0, 1 - distOutside / bandWidth);
}

function scoreDistance(school, criteria) {
  if (criteria.lat == null || criteria.lng == null) return 0.5; // neutral
  const sLat = Number(school.latitude);
  const sLng = Number(school.longitude);
  if (!Number.isFinite(sLat) || !Number.isFinite(sLng)) return 0;
  const km = haversineKm(criteria.lat, criteria.lng, sLat, sLng);
  // Exponential decay scaled by preferred radius. A school exactly at the
  // preferred radius scores e^-1 ≈ 0.37; closer schools approach 1.
  const r = criteria.preferredRadiusKm > 0 ? criteria.preferredRadiusKm : 25;
  return Math.exp(-km / r);
}

function scoreRating(school) {
  // school.rating is a Decimal in [0..5]; convert + clamp.
  const rating = Number(school.rating ?? 0);
  if (!Number.isFinite(rating) || rating <= 0) return 0;
  return Math.min(1, rating / 5);
}

function scoreFacilities(school) {
  if (!school.facilities) return 0;
  const items = String(school.facilities)
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
  // Saturating: 5 or more facilities → full credit; below that, linear.
  return Math.min(1, items.length / 5);
}

function scoreVerification(school) {
  switch (school.verificationStatus) {
    case "VERIFIED":
      return 1;
    case "PENDING":
      return 0.4;
    case "REJECTED":
      return 0;
    default:
      return 0;
  }
}

/**
 * Score a single school against resolved criteria. Returns a number in
 * [0..100] and a per-signal breakdown for explainability/debugging.
 */
export function scoreSchool(school, criteria, weights = RECOMMENDATION_WEIGHTS) {
  const components = {
    curriculum: scoreCurriculum(school, criteria),
    budget: scoreBudget(school, criteria),
    distance: scoreDistance(school, criteria),
    rating: scoreRating(school),
    facilities: scoreFacilities(school),
    verification: scoreVerification(school),
  };
  const score = Object.entries(components).reduce(
    (acc, [k, v]) => acc + v * (weights[k] ?? 0),
    0
  );
  return { score: Number(score.toFixed(2)), components };
}

/**
 * Public API: rank `schools` for the given parent + query overrides.
 *
 * `userId` is the authenticated parent's id (we look up their Parent +
 * Preference rows to seed the criteria). `query` is the raw req.query —
 * any of `curriculum`, `minFee`, `maxFee`, `near`, `radiusKm` can override.
 */
export async function getRecommendations(schools, query = {}, userId = null) {
  const ctx = await loadParentContext(userId);
  const criteria = resolveCriteria(query, ctx);

  const ranked = schools
    .map((s) => {
      const { score, components } = scoreSchool(s, criteria);
      return { ...s, score, breakdown: components };
    })
    .sort((a, b) => b.score - a.score);

  return { ranked, criteria };
}
