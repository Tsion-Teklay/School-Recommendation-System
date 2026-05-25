import { db } from "../config/db.js";
import { scoreSchool, MOE_RANKING_WEIGHTS } from "./scoring.service.js"; 
  

// Neutral criteria for system-wide ranking (no parent preferences)  
const NEUTRAL_CRITERIA = {  
  curriculum: null,  
  minBudget: null,  
  maxBudget: null,  
  lat: null,  
  lng: null,  
  preferredRadiusKm: 25,  
};  

// ✅ Add analytics data
export async function createAnalytics(data) {
  return db.analytics.create({
    data: {
      ...data,
      schoolId: Number(data.schoolId),
    },
  });
}

// ✅ Get analytics for one school
export async function getSchoolAnalytics(schoolId) {
  const id = Number(schoolId);

  const [analytics, reviewStats, favoriteCount, followerCount] =
    await Promise.all([
      db.analytics.findMany({
        where: { schoolId: id },
        orderBy: { academicYear: "desc" },
      }),
      db.review.aggregate({
        where: { schoolId: id },
        _avg: { rating: true },
        _count: true,
      }),
      db.favorite.count({ where: { schoolId: id } }),
      db.subscription.count({ where: { schoolId: id } }),
    ]);

  return {
    analytics,
    stats: {
      averageRating: Number(reviewStats._avg.rating) || 0,
      totalReviews: reviewStats._count,
      favorites: favoriteCount,
      followers: followerCount,
    },
  };
}

export async function getDashboard() {
  try {
    const [
      totalUsers,
      totalSchools,
      totalReviews,
      totalAnnouncements,
      totalReports,
      totalForumPosts,
      totalFollows,
      usersByRoleRaw,
      schoolsByVerificationRaw,
      schoolsBySubcityRaw,
      reportsByStatusRaw,
      reviewAvg,
    ] = await Promise.all([
      db.user.count(),
      db.school.count(),
      db.review.count(),
      db.announcement.count(),
      db.report.count(),
      db.discussionForum.count(),
      db.subscription.count(),
      db.user.groupBy({ by: ["role"], _count: { _all: true } }),
      db.school.groupBy({
        by: ["verificationStatus"],
        _count: { _all: true },
      }),
      db.school.groupBy({
        by: ["subCity"],
        _count: { _all: true },
        where: { subCity: { not: null } },
      }),
      db.report.groupBy({ by: ["status"], _count: { _all: true } }),
      db.review.aggregate({ _avg: { rating: true } }),
    ]);

    console.log('Basic queries completed');

    const flattenGroup = (rows, key) =>
      rows.reduce((acc, row) => {
        acc[row[key]] = row._count?._all ?? 0;
        return acc;
      }, {});

    return {
      summary: {
        totalUsers,
        totalSchools,
        totalReviews,
        totalAnnouncements,
        totalReports,
        totalForumPosts,
        totalFollows,
        averageRating: Number(reviewAvg._avg.rating) || 0,
      },
      usersByRole: flattenGroup(usersByRoleRaw, "role"),
      schoolsByVerification: flattenGroup(
        schoolsByVerificationRaw,
        "verificationStatus"
      ),
      schoolsBySubcity: flattenGroup(schoolsBySubcityRaw, "subCity"),
      reportsByStatus: flattenGroup(reportsByStatusRaw, "status"),
      topSchools: [],
      mostFollowed: [],
      signupsLast30Days: [],
      moeRanking: [],
    };
  } catch (error) {
    console.error('Dashboard error:', error);
    throw error;
  }
}


function csvEscape(value) {
  if (value == null) return "";
  const s = String(value);
  return /[",\n\r]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}

function csvRow(values) {
  return values.map(csvEscape).join(",");
}

export async function getDashboardCsv() {
  const dash = await getDashboard();
  const lines = [];

  lines.push("Section,Key,Value");
  for (const [k, v] of Object.entries(dash.summary)) {
    lines.push(csvRow(["summary", k, v]));
  }
  for (const [k, v] of Object.entries(dash.usersByRole)) {
    lines.push(csvRow(["usersByRole", k, v]));
  }
  for (const [k, v] of Object.entries(dash.schoolsByVerification)) {
    lines.push(csvRow(["schoolsByVerification", k, v]));
  }
  for (const [k, v] of Object.entries(dash.reportsByStatus)) {
    lines.push(csvRow(["reportsByStatus", k, v]));
  }

  lines.push("");
  lines.push("Top schools by rating");
  lines.push(csvRow(["id", "name", "rating", "reviews", "verification"]));
  for (const s of dash.topSchools) {
    lines.push(
      csvRow([
        s.id,
        s.schoolName,
        s.rating,
        s.reviewCount,
        s.verificationStatus,
      ])
    );
  }

  lines.push("");
  lines.push("Most followed schools");
  lines.push(csvRow(["id", "name", "followers"]));
  for (const s of dash.mostFollowed) {
    lines.push(csvRow([s.schoolId, s.schoolName, s.followers]));
  }

  return lines.join("\n") + "\n";
}


export async function calculateAchievementScore(schoolId) {  
  const achievements = await db.achievement.findMany({  
    where: { schoolId, status: "APPROVED" },  
    select: { score: true }  
  });  
    
  return achievements.reduce((sum, a) => sum + a.score, 0);  
}  
  
/**  
 * Calculate gender balance index (ratio closer to 1 = more balanced)  
 */  
export async function calculateGenderBalanceIndex(schoolId) {  
  const latestDemographics = await db.schoolDemographics.findFirst({  
    where: { schoolId },  
    orderBy: { academicYear: 'desc' }  
  });  
    
  if (!latestDemographics || latestDemographics.totalStudents === 0) return 0;  
    
  const girlsRatio = latestDemographics.girlsCount / latestDemographics.totalStudents;  
  const boysRatio = latestDemographics.boysCount / latestDemographics.totalStudents;  
    
  // Index: 1 - |girlsRatio - boysRatio| (1 = perfectly balanced, 0 = completely imbalanced)  
  return Math.max(0, 1 - Math.abs(girlsRatio - boysRatio));  
}  
  
/**  
 * Calculate year-over-year growth in passing rate  
 */  
export async function calculateYearOverYearGrowth(schoolId) {  
  const demographics = await db.schoolDemographics.findMany({  
    where: { schoolId },  
    orderBy: { academicYear: 'desc' },  
    take: 2  
  });  
    
  if (demographics.length < 2) return 0;  
    
  const current = demographics[0].passingRate;  
  const previous = demographics[1].passingRate;  
    
  if (previous === 0) return 0;  
  return ((current - previous) / previous) * 100;  
}  
  
/**  
 * Calculate percentile ranking based on national exam score  
 */  
export async function calculatePercentileRanking(schoolId) {  
  const school = await db.school.findUnique({  
    where: { id: schoolId },  
    include: {  
      demographics: {  
        orderBy: { academicYear: 'desc' },  
        take: 1  
      }  
    }  
  });  
    
  if (!school || school.demographics.length === 0) return 0;  
    
  const currentScore = school.demographics[0].nationalExamScore;  
    
  // Get all schools with demographics for the same year  
  const allSchools = await db.schoolDemographics.findMany({  
    where: { academicYear: school.demographics[0].academicYear },  
    select: { nationalExamScore: true }  
  });  
    
  if (allSchools.length === 0) return 0;  
    
  const schoolsBelow = allSchools.filter(s => s.nationalExamScore < currentScore).length;  
  return (schoolsBelow / allSchools.length) * 100;  
}  
  
/**  
 * Calculate parent engagement score (based on subscriptions, reviews, forum participation)  
 */  
export async function calculateParentEngagementScore(schoolId) {  
  const [subscriberCount, reviewCount, forumPostCount] = await Promise.all([  
    db.subscription.count({ where: { schoolId } }),  
    db.review.count({ where: { schoolId } }),  
    db.discussionForum.count({ where: { schoolId } })  
  ]);  
    
  // Weighted score: subscribers (40%), reviews (30%), forum posts (30%)  
  // Normalize against reasonable max values  
  const subscriberScore = Math.min(subscriberCount / 100, 1) * 40;  
  const reviewScore = Math.min(reviewCount / 50, 1) * 30;  
  const forumScore = Math.min(forumPostCount / 20, 1) * 30;  
    
  return subscriberScore + reviewScore + forumScore;  
}  
  
/**  
 * Calculate community trust score (based on rating, verification status, report count)  
 */  
export async function calculateCommunityTrustScore(schoolId) {  
  const school = await db.school.findUnique({  
    where: { id: schoolId },  
    include: {  
      _count: {  
        select: { reports: true }  
      }  
    }  
  });  
    
  if (!school) return 0;  
    
  // Rating component (0-50 points)  
  const ratingScore = (school.rating / 5) * 50;  
    
  // Verification bonus (0-30 points)  
  const verificationBonus = school.verificationStatus === "VERIFIED" ? 30 : 0;  
    
  // Report penalty (0-20 points deducted)  
  const reportPenalty = Math.min(school._count.reports * 5, 20);  
    
  return Math.max(0, ratingScore + verificationBonus - reportPenalty);  
}  
  
/**  
 * Get comprehensive school analytics for parents  
 */  
export async function getSchoolCompositeAnalytics(schoolId) {  
  try {
    console.log('Fetching analytics for school:', schoolId);
    
    // TEMP: Add back calculations one by one
    const achievementScore = await calculateAchievementScore(schoolId);
    const genderBalanceIndex = await calculateGenderBalanceIndex(schoolId);
    const yearOverYearGrowth = await calculateYearOverYearGrowth(schoolId);
    const percentileRanking = await calculatePercentileRanking(schoolId);
    
    // TEMP: Disable problematic calculations
    const parentEngagementScore = 0;
    const communityTrustScore = 0;
    
    const [demographics, achievements] = await Promise.all([  
      db.schoolDemographics.findMany({  
        where: { schoolId },  
        orderBy: { academicYear: 'desc' }  
      }),  
      db.achievement.findMany({  
        where: { schoolId, status: "APPROVED" },  
        orderBy: { year: 'desc' }  
      })  
    ]);  
    
    console.log('Basic queries completed');
    
    // Return with all calculations
    return {  
      achievementScore,  
      genderBalanceIndex,  
      yearOverYearGrowth,  
      percentileRanking,  
      parentEngagementScore,  
      communityTrustScore,  
      demographics,  
      achievements  
    };  
  } catch (error) {
    console.error('School analytics error:', error);
    throw error;
  }
}