export const RECOMMENDATION_WEIGHTS = Object.freeze({  
  curriculum: 25,  
  budget: 20,  
  distance: 20,  
  rating: 15,  
  facilities: 10,  
  verification: 10,  
});  
  
// You can define specific MoE weights here if you want them to differ
export const MOE_RANKING_WEIGHTS = Object.freeze({
  rating: 25,           // Rating: 25%
  verification: 20,     // Verification: 20%
  facilities: 15,       // Facilities: 15%
  achievement: 15,      // Achievement score: 15%
  genderBalance: 10,    // Gender balance index: 10%
  passingRate: 10,      // Passing rate: 10%
  nationalExam: 5,      // National exam score: 5%
  curriculum: 0,        // Not used for MOE ranking
  budget: 0,            // Not used for MOE ranking
  distance: 0,          // No distance preference for MOE ranking
  schoolLevel: 0,       // Not used for MOE ranking
  schoolType: 0,        // Not used for MOE ranking
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
  
  if (  
    (minBudget == null || fee >= minBudget) &&  
    (maxBudget == null || fee <= maxBudget)  
  ) {  
    return 1;  
  }  
  
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
  const r = criteria.preferredRadiusKm > 0 ? criteria.preferredRadiusKm : 25;  
  return Math.exp(-km / r);  
}  
  
function scoreRating(school) {  
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

export function scoreSchoolLevel(school, criteria) {  
  // Binary match: if parent has a level preference, match it  
  if (!criteria.schoolLevel) return 0.5; // Neutral if no preference  
  return school.schoolLevel === criteria.schoolLevel ? 1 : 0;  
}  
  
export function scoreSchoolType(school, criteria) {  
  // Binary match: if parent has a type preference, match it  
  if (!criteria.schoolType) return 0.5; // Neutral if no preference  
  return school.schoolType === criteria.schoolType ? 1 : 0;  
}  
  
export function scorePassingRate(school) {  
  // Linear scaling: 0-100% maps to 0-1  
  if (!school.passingRate) return 0;  
  return Number(school.passingRate) / 100;  
}  
  
export function scoreNationalExamScore(school) {
  // Linear scaling: 0-100% maps to 0-1
  if (!school.nationalExamScore) return 0;
  return Number(school.nationalExamScore) / 100;
}

export function scoreAchievement(school) {
  // Normalize achievement score (0-500 maps to 0-1)
  if (!school.achievementScore) return 0;
  return Math.min(1, school.achievementScore / 500);
}

export function scoreGenderBalance(school) {
  // Gender balance index: 1 = perfectly balanced, 0 = completely imbalanced
  if (!school.genderBalanceIndex) return 0;
  return school.genderBalanceIndex;
}
  
/**
 * Score a single school against resolved criteria.
 * Returns a number in [0..100] and a per-signal breakdown.
 */
export function scoreSchool(school, criteria, weights) {
  const signals = {
    curriculum: scoreCurriculum(school, criteria),
    budget: scoreBudget(school, criteria),
    distance: scoreDistance(school, criteria),
    rating: scoreRating(school),
    facilities: scoreFacilities(school),
    verification: scoreVerification(school),
    schoolLevel: scoreSchoolLevel(school, criteria),
    schoolType: scoreSchoolType(school, criteria),
    passingRate: scorePassingRate(school),
    nationalExamScore: scoreNationalExamScore(school),
    achievement: scoreAchievement(school),
    genderBalance: scoreGenderBalance(school),
  };

  const score = Object.entries(weights).reduce((sum, [key, weight]) => {
    return sum + (signals[key] || 0) * weight;
  }, 0);

  return { score, signals };
}