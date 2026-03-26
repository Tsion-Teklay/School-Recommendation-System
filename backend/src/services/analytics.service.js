import { db } from "../config/db.js";

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
  const analytics = await db.analytics.findMany({
    where: { schoolId: Number(schoolId) },
    orderBy: { academicYear: "desc" },
  });

  const reviewStats = await db.review.aggregate({
    where: { schoolId: Number(schoolId) },
    _avg: { rating: true },
    _count: true,
  });

  const favoriteCount = await db.favorite.count({
    where: { schoolId: Number(schoolId) },
  });

  return {
    analytics,
    stats: {
      averageRating: reviewStats._avg.rating || 0,
      totalReviews: reviewStats._count,
      favorites: favoriteCount,
    },
  };
}

// ✅ Dashboard
export async function getDashboard() {
  const [schools, users, reviews] = await Promise.all([
    db.school.count(),
    db.user.count(),
    db.review.count(),
  ]);

  const topSchools = await db.school.findMany({
    take: 5,
    include: {
      reviews: true,
      favorites: true,
    },
  });

  return {
    summary: {
      totalSchools: schools,
      totalUsers: users,
      totalReviews: reviews,
    },
    topSchools,
  };
}