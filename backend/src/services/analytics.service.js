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

    console.log("Basic queries completed");

    const flattenGroup = (rows, key) =>
      rows.reduce((acc, row) => {
        acc[row[key]] = row._count?._all ?? 0;
        return acc;
      }, {});

    // Get top schools by rating
    const topSchoolsRaw = await db.school.findMany({
      where: { rating: { gt: 0 } },
      orderBy: { rating: "desc" },
      take: 10,
      include: {
        _count: {
          select: { reviews: true },
        },
      },
    });

    const topSchools = topSchoolsRaw.map((s) => ({
      id: s.id,
      schoolName: s.schoolName,
      rating: Number(s.rating),
      reviewCount: s._count.reviews,
      verificationStatus: s.verificationStatus,
    }));

    // Get most followed schools
    const mostFollowedRaw = await db.school.findMany({
      orderBy: {
        subscribers: {
          _count: "desc",
        },
      },
      take: 10,
      include: {
        _count: {
          select: { subscribers: true },
        },
      },
    });

    const mostFollowed = mostFollowedRaw.map((s) => ({
      schoolId: s.id,
      schoolName: s.schoolName,
      followers: s._count.subscribers,
    }));

    // Get MOE ranking with updated weights
    const allSchools = await db.school.findMany({
      include: {
        demographics: {
          orderBy: { academicYear: "desc" },
          take: 1,
        },
        achievements: {
          where: { status: "APPROVED" },
        },
        _count: {
          select: { subscribers: true, reviews: true },
        },
      },
    });

    const moeRanking = await Promise.all(
      allSchools.map(async (school) => {
        const achievementScore = school.achievements.reduce(
          (sum, a) => sum + (a.score || 0),
          0,
        );
        const latestDemographics = school.demographics[0];

        // Calculate gender balance index
        let genderBalanceIndex = 0;
        if (latestDemographics && latestDemographics.totalStudents > 0) {
          const girlsRatio =
            latestDemographics.girlsCount / latestDemographics.totalStudents;
          const boysRatio =
            latestDemographics.boysCount / latestDemographics.totalStudents;
          genderBalanceIndex = Math.max(
            0,
            1 - Math.abs(girlsRatio - boysRatio),
          );
        }

        // Calculate passing rate score
        const passingRateScore = latestDemographics
          ? (latestDemographics.passingRate || 0) / 100
          : 0;

        // Calculate national exam score
        const nationalExamScore = latestDemographics
          ? (latestDemographics.nationalExamScore || 0) / 100
          : 0;

        // Calculate rating score
        const ratingScore = (school.rating || 0) / 5;

        // Calculate verification score
        let verificationScore = 0;
        switch (school.verificationStatus) {
          case "VERIFIED":
            verificationScore = 1;
            break;
          case "PENDING":
            verificationScore = 0.4;
            break;
          case "REJECTED":
            verificationScore = 0;
            break;
          default:
            verificationScore = 0;
        }

        // Calculate facilities score
        const facilities = school.facilities
          ? school.facilities.split(",").length
          : 0;
        const facilitiesScore = Math.min(1, facilities / 5);

        // Calculate achievement score (normalized to 0-1)
        const achievementScoreNormalized = Math.min(1, achievementScore / 500);

        // MOE Ranking weights (updated based on user requirements)
        const weights = {
          rating: 25, // Rating: 25%
          verification: 20, // Verification: 20%
          facilities: 15, // Facilities: 15%
          achievement: 15, // Achievement score: 15%
          genderBalance: 10, // Gender balance index: 10%
          passingRate: 10, // Passing rate: 10%
          nationalExam: 5, // National exam score: 5%
        };

        const totalScore =
          ratingScore * weights.rating +
          verificationScore * weights.verification +
          facilitiesScore * weights.facilities +
          achievementScoreNormalized * weights.achievement +
          genderBalanceIndex * weights.genderBalance +
          passingRateScore * weights.passingRate +
          nationalExamScore * weights.nationalExam;

        return {
          schoolId: school.id,
          schoolName: school.schoolName,
          totalScore: Math.round(totalScore),
          breakdown: {
            rating: Math.round(ratingScore * weights.rating),
            verification: Math.round(verificationScore * weights.verification),
            facilities: Math.round(facilitiesScore * weights.facilities),
            achievement: Math.round(
              achievementScoreNormalized * weights.achievement,
            ),
            genderBalance: Math.round(
              genderBalanceIndex * weights.genderBalance,
            ),
            passingRate: Math.round(passingRateScore * weights.passingRate),
            nationalExam: Math.round(nationalExamScore * weights.nationalExam),
          },
        };
      }),
    );

    // Sort by total score descending
    moeRanking.sort((a, b) => b.totalScore - a.totalScore);

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
        "verificationStatus",
      ),
      schoolsBySubcity: flattenGroup(schoolsBySubcityRaw, "subCity"),
      reportsByStatus: flattenGroup(reportsByStatusRaw, "status"),
      topSchools,
      mostFollowed,
      signupsLast30Days: [],
      moeRanking,
    };
  } catch (error) {
    console.error("Dashboard error:", error);
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
      ]),
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
    select: { score: true },
  });

  return achievements.reduce((sum, a) => sum + a.score, 0);
}

/**
 * Calculate gender balance index (ratio closer to 1 = more balanced)
 */
export async function calculateGenderBalanceIndex(schoolId) {
  const latestDemographics = await db.schoolDemographics.findFirst({
    where: { schoolId },
    orderBy: { academicYear: "desc" },
  });

  if (!latestDemographics || latestDemographics.totalStudents === 0) return 0;

  const girlsRatio =
    latestDemographics.girlsCount / latestDemographics.totalStudents;
  const boysRatio =
    latestDemographics.boysCount / latestDemographics.totalStudents;

  // Index: 1 - |girlsRatio - boysRatio| (1 = perfectly balanced, 0 = completely imbalanced)
  return Math.max(0, 1 - Math.abs(girlsRatio - boysRatio));
}

/**
 * Calculate year-over-year growth in passing rate
 */
export async function calculateYearOverYearGrowth(schoolId) {
  const demographics = await db.schoolDemographics.findMany({
    where: { schoolId },
    orderBy: { academicYear: "desc" },
    take: 2,
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
        orderBy: { academicYear: "desc" },
        take: 1,
      },
    },
  });

  if (!school || school.demographics.length === 0) return 0;

  const currentScore = school.demographics[0].nationalExamScore;

  // Get all schools with demographics for the same year
  const allSchools = await db.schoolDemographics.findMany({
    where: { academicYear: school.demographics[0].academicYear },
    select: { nationalExamScore: true },
  });

  if (allSchools.length === 0) return 0;

  const schoolsBelow = allSchools.filter(
    (s) => s.nationalExamScore < currentScore,
  ).length;
  return (schoolsBelow / allSchools.length) * 100;
}

/**
 * Calculate parent engagement score (based on subscriptions, reviews)
 */
export async function calculateParentEngagementScore(schoolId) {
  const [subscriberCount, reviewCount] = await Promise.all([
    db.subscription.count({ where: { schoolId } }),
    db.review.count({ where: { schoolId } }),
  ]);

  // Forum posts are not directly associated with schools in current schema
  const forumPostCount = 0;

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
  });

  if (!school) return 0;

  // Rating component (0-70 points)
  const ratingScore = (school.rating / 5) * 70;

  // Verification bonus (0-30 points)
  const verificationBonus = school.verificationStatus === "VERIFIED" ? 30 : 0;

  return Math.max(0, ratingScore + verificationBonus);
}

/**
 * Calculate staff quality score (based on education levels)
 */
export async function calculateStaffQualityScore(schoolId) {
  const staffBreakdowns = await db.staffBreakdown.findMany({
    where: { schoolId },
  });

  if (staffBreakdowns.length === 0) return 0;

  const phdCount =
    staffBreakdowns.find((s) => s.educationLevel === "PHD")?.count || 0;
  const mastersCount =
    staffBreakdowns.find((s) => s.educationLevel === "MASTERS")?.count || 0;
  const degreeCount =
    staffBreakdowns.find((s) => s.educationLevel === "DEGREE")?.count || 0;
  const totalStaff = staffBreakdowns.reduce((sum, s) => sum + s.count, 0);

  if (totalStaff === 0) return 0;

  // Weighted score: PhD (4), Masters (3), Degree (2), others (0)
  // Normalized to 0-1 by dividing by (totalStaff * 4)
  return (phdCount * 4 + mastersCount * 3 + degreeCount * 2) / (totalStaff * 4);
}

/**
 * Batch calculate analytics metrics for multiple schools
 * Optimized to reduce N+1 query problems
 */
export async function batchCalculateSchoolAnalytics(schoolIds) {
  if (!schoolIds || schoolIds.length === 0) return {};

  const results = {};

  // Fetch all necessary data in batch
  const [allDemographics, allAchievements, allStaffBreakdowns, allSchools] =
    await Promise.all([
      db.schoolDemographics.findMany({
        where: { schoolId: { in: schoolIds } },
        orderBy: { academicYear: "desc" },
      }),
      db.achievement.findMany({
        where: {
          schoolId: { in: schoolIds },
          status: "APPROVED",
        },
      }),
      db.staffBreakdown.findMany({
        where: { schoolId: { in: schoolIds } },
      }),
      db.school.findMany({
        where: { id: { in: schoolIds } },
        include: {
          _count: {
            select: {
              subscribers: true,
              reviews: true,
              reports: true,
            },
          },
        },
      }),
    ]);

  // Group data by schoolId
  const demographicsBySchool = {};
  allDemographics.forEach((d) => {
    if (!demographicsBySchool[d.schoolId]) {
      demographicsBySchool[d.schoolId] = [];
    }
    demographicsBySchool[d.schoolId].push(d);
  });

  const achievementsBySchool = {};
  allAchievements.forEach((a) => {
    if (!achievementsBySchool[a.schoolId]) {
      achievementsBySchool[a.schoolId] = [];
    }
    achievementsBySchool[a.schoolId].push(a);
  });

  const staffBySchool = {};
  allStaffBreakdowns.forEach((s) => {
    if (!staffBySchool[s.schoolId]) {
      staffBySchool[s.schoolId] = [];
    }
    staffBySchool[s.schoolId].push(s);
  });

  const schoolsById = {};
  allSchools.forEach((s) => {
    schoolsById[s.id] = s;
  });

  // Calculate metrics for each school
  for (const schoolId of schoolIds) {
    const school = schoolsById[schoolId];
    if (!school) continue;

    const demographics = demographicsBySchool[schoolId] || [];
    const achievements = achievementsBySchool[schoolId] || [];
    const staffBreakdowns = staffBySchool[schoolId] || [];

    // Achievement score
    const achievementScore = achievements.reduce(
      (sum, a) => sum + (a.score || 0),
      0,
    );

    // Gender balance index
    let genderBalanceIndex = 0;
    const latestDemographics = demographics[0];
    if (latestDemographics && latestDemographics.totalStudents > 0) {
      const girlsRatio =
        latestDemographics.girlsCount / latestDemographics.totalStudents;
      const boysRatio =
        latestDemographics.boysCount / latestDemographics.totalStudents;
      genderBalanceIndex = Math.max(0, 1 - Math.abs(girlsRatio - boysRatio));
    }

    // Year-over-year growth
    let yearOverYearGrowth = 0;
    if (demographics.length >= 2) {
      const current = demographics[0].passingRate;
      const previous = demographics[1].passingRate;
      if (previous !== 0) {
        yearOverYearGrowth = ((current - previous) / previous) * 100;
      }
    }

    // Staff quality score
    let staffQualityScore = 0;
    if (staffBreakdowns.length > 0) {
      const phdCount =
        staffBreakdowns.find((s) => s.educationLevel === "PHD")?.count || 0;
      const mastersCount =
        staffBreakdowns.find((s) => s.educationLevel === "MASTERS")?.count || 0;
      const degreeCount =
        staffBreakdowns.find((s) => s.educationLevel === "DEGREE")?.count || 0;
      const totalStaff = staffBreakdowns.reduce((sum, s) => sum + s.count, 0);

      if (totalStaff > 0) {
        staffQualityScore =
          (phdCount * 4 + mastersCount * 3 + degreeCount * 2) /
          (totalStaff * 4);
      }
    }

    // Parent engagement score
    const subscriberCount = school._count?.subscribers || 0;
    const reviewCount = school._count?.reviews || 0;
    const subscriberScore = Math.min(subscriberCount / 100, 1) * 70;
    const reviewScore = Math.min(reviewCount / 50, 1) * 30;
    const parentEngagementScore = subscriberScore + reviewScore;

    // Community trust score
    const ratingScore = (school.rating / 5) * 60;

    const verificationBonus = school.verificationStatus === "VERIFIED" ? 30 : 0;
    const reportPenalty = Math.min((school._count?.reports || 0) * 5, 20);
    const communityTrustScore = Math.max(
      0,
      ratingScore + verificationBonus - reportPenalty,
    );

    results[schoolId] = {
      achievementScore,
      genderBalanceIndex,
      yearOverYearGrowth,
      staffQualityScore,
      parentEngagementScore,
      communityTrustScore,
      totalStudents: latestDemographics?.totalStudents || 0,
      followerCount: subscriberCount,
      reviewCount: reviewCount,
      academicYear: latestDemographics?.academicYear || null,
    };
  }

  return results;
}

/**
 * Get comprehensive school analytics for parents
 */
export async function getSchoolCompositeAnalytics(schoolId) {
  try {
    console.log("Fetching analytics for school:", schoolId);

    // TEMP: Add back calculations one by one
    const achievementScore = await calculateAchievementScore(schoolId);
    const genderBalanceIndex = await calculateGenderBalanceIndex(schoolId);
    const yearOverYearGrowth = await calculateYearOverYearGrowth(schoolId);
    const percentileRanking = await calculatePercentileRanking(schoolId);

    // Re-enable calculations with batch optimization
    const parentEngagementScore =
      await calculateParentEngagementScore(schoolId);
    const communityTrustScore = await calculateCommunityTrustScore(schoolId);
    const staffQualityScore = await calculateStaffQualityScore(schoolId);

    const [demographics, achievements] = await Promise.all([
      db.schoolDemographics.findMany({
        where: { schoolId },
        orderBy: { academicYear: "desc" },
      }),
      db.achievement.findMany({
        where: { schoolId, status: "APPROVED" },
        orderBy: { year: "desc" },
      }),
    ]);

    console.log("Basic queries completed");

    // Return with all calculations
    return {
      achievementScore,
      genderBalanceIndex,
      yearOverYearGrowth,
      percentileRanking,
      parentEngagementScore,
      communityTrustScore,
      staffQualityScore,
      demographics,
      achievements,
    };
  } catch (error) {
    console.error("School analytics error:", error);
    throw error;
  }
}
