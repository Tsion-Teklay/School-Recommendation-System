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

/**
 * Phase 6 — real MoE dashboard.
 *
 * Replaces the Phase 0 mock (which returned `topSchools` with raw `reviews`
 * + `favorites` arrays — useless for a dashboard) with structured aggregates
 * computed from the actual tables.
 *
 * All counts are computed in parallel against the live tables. The shape is
 * stable and CSV-flattenable (see `getDashboardCsv`) so MoE officers can
 * pull the same numbers into Excel without an extra reporting endpoint.
 */
export async function getDashboard() {
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
    reportsByStatusRaw,
    reviewAvg,
    topSchools,
    mostFollowedRaw,
    recentSignupsRaw,
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
    db.report.groupBy({ by: ["status"], _count: { _all: true } }),
    db.review.aggregate({ _avg: { rating: true } }),
    db.school.findMany({
      where: { reviewCount: { gt: 0 } },
      orderBy: [{ rating: "desc" }, { reviewCount: "desc" }],
      take: 5,
      select: {
        id: true,
        schoolName: true,
        rating: true,
        reviewCount: true,
        verificationStatus: true,
      },
    }),
    db.subscription.groupBy({
      by: ["schoolId"],
      _count: { _all: true },
      orderBy: { _count: { schoolId: "desc" } },
      take: 5,
    }),
    db.user.findMany({
      where: {
        createdAt: { gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) },
      },
      select: { createdAt: true },
    }),
  ]);

  // groupBy returns rows like `[{ role: "PARENT", _count: { _all: 5 } }]`;
  // flatten to a `{ PARENT: 5, MODERATOR: 1, ... }` shape that's friendly
  // to dashboards and CSV.
  const flattenGroup = (rows, key) =>
    rows.reduce((acc, row) => {
      acc[row[key]] = row._count?._all ?? 0;
      return acc;
    }, {});

  // Hydrate the most-followed schools with their names so the dashboard
  // doesn't need a second roundtrip just to render the list.
  const mostFollowedIds = mostFollowedRaw.map((r) => r.schoolId);
  const mostFollowedSchools = mostFollowedIds.length
    ? await db.school.findMany({
        where: { id: { in: mostFollowedIds } },
        select: { id: true, schoolName: true },
      })
    : [];
  const nameById = new Map(
    mostFollowedSchools.map((s) => [s.id, s.schoolName])
  );
  const mostFollowed = mostFollowedRaw.map((row) => ({
    schoolId: row.schoolId,
    schoolName: nameById.get(row.schoolId) ?? null,
    followers: row._count?._all ?? 0,
  }));

  // Bucket the last 30 days of signups by ISO date for a sparkline.
  const signupsByDay = {};
  for (let i = 29; i >= 0; i--) {
    const d = new Date(Date.now() - i * 24 * 60 * 60 * 1000);
    signupsByDay[d.toISOString().slice(0, 10)] = 0;
  }
  for (const u of recentSignupsRaw) {
    const day = u.createdAt.toISOString().slice(0, 10);
    if (day in signupsByDay) signupsByDay[day] += 1;
  }
  const signupsLast30Days = Object.entries(signupsByDay).map(
    ([date, count]) => ({ date, count })
  );

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
    reportsByStatus: flattenGroup(reportsByStatusRaw, "status"),
    topSchools: topSchools.map((s) => ({
      ...s,
      rating: Number(s.rating),
    })),
    mostFollowed,
    signupsLast30Days,
  };
}

/**
 * CSV-flatten the dashboard for Excel/Sheets export.
 *
 * Produces a multi-section CSV (Summary, Users by role, Schools by status,
 * Top schools, Most followed). Each section gets its own header row so
 * Excel renders them as distinct tables when copy-pasted.
 *
 * No external CSV library — values are simple integers/strings, and the
 * tiny escaper below handles the only edge case (school names containing
 * commas, quotes, or newlines).
 */
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
