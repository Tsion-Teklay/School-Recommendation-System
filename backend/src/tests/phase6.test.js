/**
 * Phase 6 — content-based recommender + real MoE analytics + CSV export.
 *
 * Covers:
 *   - Recommender weighting: a fully-matching school outranks a partially-
 *     matching one, parent preferences seed the score, query overrides win,
 *     verification status produces a tiebreaker.
 *   - Dashboard aggregates match the live row counts (totals, group-bys,
 *     average rating, top schools, most followed).
 *   - CSV export emits text/csv with the same numbers as the JSON dashboard.
 */
import request from "supertest";
import app from "../app.js";
import { db } from "../config/db.js";
import { cleanDatabase } from "./utils/cleanup.js";
import { registerVerifiedUser } from "./utils/auth.js";

let parentToken;
let parentId;
let parentBToken;
let parentBId;
let moeToken;
let adminToken;
let adminId;

// Three schools, deliberately positioned to differentiate ranking signals.
let perfectSchoolId; // INTERNATIONAL, in-budget, near, verified, 5+ facilities
let okSchoolId;      // INTERNATIONAL, in-budget, near, pending, 2 facilities
let badSchoolId;     // LOCAL,         out-of-budget, far, rejected, no facilities

beforeAll(async () => {
  await cleanDatabase();

  // Parent A — has a saved Preference record so the recommender can read it.
  ({ token: parentToken, user: { id: parentId } } = await registerVerifiedUser({
    fullName: "Parent",
    email: "p6-parent@test.com",
    phone: "+251911600001",
    role: "PARENT",
  }));
  await db.parent.create({
    data: { userId: parentId, latitude: 9.0, longitude: 38.0 },
  });
  await db.preference.create({
    data: {
      parentId,
      minBudget: "1000.00",
      maxBudget: "5000.00",
      curriculum: "INTERNATIONAL",
      distance: 25,
    },
  });

  // Parent B — no Preference profile, used to exercise the neutral fallback.
  ({ token: parentBToken, user: { id: parentBId } } = await registerVerifiedUser({
    fullName: "Parent B",
    email: "p6-parentB@test.com",
    phone: "+251911600002",
    role: "PARENT",
  }));

  ({ token: moeToken } = await registerVerifiedUser({
    fullName: "MoE",
    email: "p6-moe@test.com",
    phone: "+251911600003",
    role: "MOE_OFFICER",
  }));

  ({ token: adminToken, user: { id: adminId } } = await registerVerifiedUser({
    fullName: "Admin",
    email: "p6-admin@test.com",
    phone: "+251911600004",
    role: "SCHOOL_ADMIN",
  }));

  // Three schools at well-separated points so distance scoring is decisive.
  // Lat 9.0 / lng 38.0 = parent's home (Addis-ish).
  const perfect = await db.school.create({
    data: {
      adminId,
      schoolName: "Perfect Academy",
      address: "1km away",
      contactEmail: "p@p6.test",
      contactPhone: "+251911600100",
      curriculum: "INTERNATIONAL",
      tuitionFee: "3000.00",
      facilities: "Library, Lab, Gym, Pool, Music Room",
      latitude: 9.005,
      longitude: 38.005,
      verificationStatus: "VERIFIED",
      rating: "5.00",
      reviewCount: 20,
    },
  });
  perfectSchoolId = perfect.id;

  const ok = await db.school.create({
    data: {
      adminId,
      schoolName: "OK School",
      address: "5km away",
      contactEmail: "o@p6.test",
      contactPhone: "+251911600101",
      curriculum: "INTERNATIONAL",
      tuitionFee: "4500.00",
      facilities: "Library, Lab",
      latitude: 9.05,
      longitude: 38.05,
      verificationStatus: "PENDING",
      rating: "3.50",
      reviewCount: 4,
    },
  });
  okSchoolId = ok.id;

  const bad = await db.school.create({
    data: {
      adminId,
      schoolName: "Bad School",
      address: "very far + over budget",
      contactEmail: "b@p6.test",
      contactPhone: "+251911600102",
      curriculum: "LOCAL",
      tuitionFee: "20000.00",
      facilities: null,
      // ~322 km away (Bahir Dar-ish vs Addis-ish).
      latitude: 11.6,
      longitude: 37.4,
      verificationStatus: "REJECTED",
      rating: "1.00",
      reviewCount: 1,
    },
  });
  badSchoolId = bad.id;
});

afterAll(async () => {
  await cleanDatabase();
  await db.$disconnect();
});

describe("Phase 6 — content-based recommender", () => {
  it("rejects unauthenticated requests", async () => {
    const res = await request(app).get("/api/recommendations");
    expect(res.statusCode).toBe(401);
  });

  it("rejects non-PARENT roles (RBAC)", async () => {
    const res = await request(app)
      .get("/api/recommendations")
      .set("Authorization", `Bearer ${moeToken}`);
    expect(res.statusCode).toBe(403);
  });

  it("ranks the perfect-fit school first using stored preferences", async () => {
    const res = await request(app)
      .get("/api/recommendations")
      .set("Authorization", `Bearer ${parentToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.data.length).toBeGreaterThanOrEqual(3);
    expect(res.body.data[0].id).toBe(perfectSchoolId);
    expect(res.body.data[res.body.data.length - 1].id).toBe(badSchoolId);
    expect(res.body.criteria).toEqual(
      expect.objectContaining({
        curriculum: "INTERNATIONAL",
        minBudget: 1000,
        maxBudget: 5000,
        preferredRadiusKm: 25,
      })
    );
  });

  it("returns a [0..100] score with a per-signal breakdown", async () => {
    const res = await request(app)
      .get("/api/recommendations")
      .set("Authorization", `Bearer ${parentToken}`);
    const top = res.body.data[0];
    expect(top.score).toBeLessThanOrEqual(100);
    expect(top.score).toBeGreaterThan(80);
    expect(top.breakdown).toEqual(
      expect.objectContaining({
        curriculum: 1,
        budget: 1,
        verification: 1,
      })
    );
    // Perfect school is ~0.7km away, radius 25km → e^(-0.7/25) ≈ 0.97.
    expect(top.breakdown.distance).toBeGreaterThan(0.9);
    expect(top.breakdown.facilities).toBe(1);
    expect(top.breakdown.rating).toBe(1);
  });

  it("query overrides win over saved preferences", async () => {
    // The parent's saved preference is INTERNATIONAL; passing
    // `?curriculum=LOCAL` re-ranks against LOCAL instead. Note the school
    // *list* filter (used by /api/schools) also kicks in here, so only LOCAL
    // schools come back — but the criteria object is what proves the
    // override took effect on the recommender side.
    const res = await request(app)
      .get("/api/recommendations?curriculum=LOCAL")
      .set("Authorization", `Bearer ${parentToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.criteria.curriculum).toBe("LOCAL");
    expect(res.body.data.every((s) => s.curriculum === "LOCAL")).toBe(true);
    const bad = res.body.data.find((s) => s.id === badSchoolId);
    expect(bad.breakdown.curriculum).toBe(1);
  });

  it("budget query override beats stored preference", async () => {
    // Parent's saved budget is 1000-5000 (matches Perfect + OK). Override to
    // a band that only the over-budget Bad school straddles (it's 20000) and
    // confirm the criteria reflects the override.
    const res = await request(app)
      .get("/api/recommendations?minFee=15000&maxFee=25000")
      .set("Authorization", `Bearer ${parentToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.criteria.minBudget).toBe(15000);
    expect(res.body.criteria.maxBudget).toBe(25000);
  });

  it("falls back to neutral defaults when the parent has no profile", async () => {
    const res = await request(app)
      .get("/api/recommendations")
      .set("Authorization", `Bearer ${parentBToken}`);
    expect(res.statusCode).toBe(200);
    // Without a Preference, curriculum / budget / distance all score 0.5
    // (neutral). Ranking is then dominated by rating + verification +
    // facilities — the perfect school still wins.
    expect(res.body.data[0].id).toBe(perfectSchoolId);
    expect(res.body.criteria.curriculum).toBeNull();
    expect(res.body.criteria.minBudget).toBeNull();
    expect(res.body.criteria.maxBudget).toBeNull();
  });

  it("verification bonus separates two otherwise-similar schools", async () => {
    const res = await request(app)
      .get("/api/recommendations")
      .set("Authorization", `Bearer ${parentToken}`);
    const perfect = res.body.data.find((s) => s.id === perfectSchoolId);
    const ok = res.body.data.find((s) => s.id === okSchoolId);
    expect(perfect.breakdown.verification).toBe(1);
    expect(ok.breakdown.verification).toBeCloseTo(0.4, 5);
    expect(perfect.score).toBeGreaterThan(ok.score);
  });
});

describe("Phase 6 — MoE dashboard", () => {
  beforeAll(async () => {
    // Seed a couple of reviews + a follow + a report so the aggregates have
    // something non-zero to compute against.
    await db.parent.upsert({
      where: { userId: parentId },
      create: { userId: parentId, latitude: 9, longitude: 38 },
      update: {},
    });
    await db.review.create({
      data: {
        parentId,
        schoolId: perfectSchoolId,
        rating: 5,
        comment: "great",
        categoryTag: "TEACHING_QUALITY",
      },
    });
    await db.review.create({
      data: {
        parentId,
        schoolId: okSchoolId,
        rating: 3,
        comment: "ok",
        categoryTag: "FACILITIES",
      },
    });
    await db.subscription.create({
      data: { parentId, schoolId: perfectSchoolId },
    });
    await db.report.create({
      data: {
        reporterId: parentId,
        targetType: "REVIEW",
        targetId: 0, // dummy; aggregator only needs the row to count
        reason: "test",
        status: "PENDING",
      },
    });
  });

  it("rejects non-MOE roles", async () => {
    const res = await request(app)
      .get("/api/analytics/dashboard")
      .set("Authorization", `Bearer ${parentToken}`);
    expect(res.statusCode).toBe(403);
  });

  it("returns live aggregates matching the seeded data", async () => {
    const res = await request(app)
      .get("/api/analytics/dashboard")
      .set("Authorization", `Bearer ${moeToken}`);
    expect(res.statusCode).toBe(200);

    const expectedUsers = await db.user.count();
    const expectedSchools = await db.school.count();

    expect(res.body.summary.totalUsers).toBe(expectedUsers);
    expect(res.body.summary.totalSchools).toBe(expectedSchools);
    expect(res.body.summary.totalReviews).toBeGreaterThanOrEqual(2);
    expect(res.body.summary.totalReports).toBeGreaterThanOrEqual(1);
    expect(res.body.summary.totalFollows).toBeGreaterThanOrEqual(1);

    expect(res.body.usersByRole.PARENT).toBeGreaterThanOrEqual(2);
    expect(res.body.usersByRole.MOE_OFFICER).toBeGreaterThanOrEqual(1);
    expect(res.body.usersByRole.SCHOOL_ADMIN).toBeGreaterThanOrEqual(1);
    expect(res.body.schoolsByVerification).toEqual(
      expect.objectContaining({
        VERIFIED: 1,
        PENDING: 1,
        REJECTED: 1,
      })
    );
  });

  it("topSchools is ordered by rating desc and skips rating-less schools", async () => {
    const res = await request(app)
      .get("/api/analytics/dashboard")
      .set("Authorization", `Bearer ${moeToken}`);
    expect(res.body.topSchools[0].id).toBe(perfectSchoolId);
    expect(res.body.topSchools.every((s) => s.reviewCount > 0)).toBe(true);
    // Returned in non-increasing rating order.
    for (let i = 1; i < res.body.topSchools.length; i++) {
      expect(res.body.topSchools[i - 1].rating).toBeGreaterThanOrEqual(
        res.body.topSchools[i].rating
      );
    }
  });

  it("mostFollowed surfaces the followed school with its name", async () => {
    const res = await request(app)
      .get("/api/analytics/dashboard")
      .set("Authorization", `Bearer ${moeToken}`);
    expect(res.body.mostFollowed[0]).toEqual(
      expect.objectContaining({
        schoolId: perfectSchoolId,
        schoolName: "Perfect Academy",
        followers: expect.any(Number),
      })
    );
    expect(res.body.mostFollowed[0].followers).toBeGreaterThanOrEqual(1);
  });

  it("signupsLast30Days has 30 entries and includes today's signups", async () => {
    const res = await request(app)
      .get("/api/analytics/dashboard")
      .set("Authorization", `Bearer ${moeToken}`);
    expect(res.body.signupsLast30Days).toHaveLength(30);
    const today = new Date().toISOString().slice(0, 10);
    const todayBucket = res.body.signupsLast30Days.find((d) => d.date === today);
    expect(todayBucket).toBeDefined();
    expect(todayBucket.count).toBeGreaterThanOrEqual(4); // we registered 4 users
  });
});

describe("Phase 6 — CSV export", () => {
  it("rejects non-MOE roles", async () => {
    const res = await request(app)
      .get("/api/analytics/dashboard.csv")
      .set("Authorization", `Bearer ${parentToken}`);
    expect(res.statusCode).toBe(403);
  });

  it("emits text/csv with summary + group sections", async () => {
    const res = await request(app)
      .get("/api/analytics/dashboard.csv")
      .set("Authorization", `Bearer ${moeToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.headers["content-type"]).toMatch(/text\/csv/);
    expect(res.headers["content-disposition"]).toMatch(/moe-dashboard-/);
    expect(res.text).toMatch(/^Section,Key,Value/);
    expect(res.text).toContain("summary,totalSchools,");
    expect(res.text).toContain("schoolsByVerification,VERIFIED,1");
    expect(res.text).toContain("Top schools by rating");
    expect(res.text).toContain("Perfect Academy");
    expect(res.text).toContain("Most followed schools");
  });
});
