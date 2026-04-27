/**
 * Phase 4 — comparisons, follow/subscribe, targeted announcement fan-out,
 * proximity search.
 *
 * Each `describe` block is a self-contained subsystem so a future split
 * into separate files (compare.test.js, follow.test.js, …) is mechanical.
 * They share a single fixture set populated in the top-level `beforeAll`
 * to keep this fast.
 */
import request from "supertest";
import app from "../app.js";
import { db } from "../config/db.js";
import { cleanDatabase } from "./utils/cleanup.js";
import { registerVerifiedUser } from "./utils/auth.js";

// Tokens
let parentAToken, parentAId;
let parentBToken;
let parentCToken;
let adminAToken, adminAId;
let adminBToken;
let moeToken;

// School IDs created via API by the admins
let schoolA1Id; // owned by adminA, near (lat 9.0, lng 38.7) — Addis Ababa-ish
let schoolA2Id; // owned by adminA
let schoolB1Id; // owned by adminB, far (lat 11.6, lng 37.4) — Bahir Dar-ish

beforeAll(async () => {
  await cleanDatabase();

  // --- Register fixture users -----------------------------------------------
  ({ token: parentAToken, user: { id: parentAId } } = await registerVerifiedUser({
    fullName: "Parent A",
    email: "parent-a@test.com",
    phone: "0911111101",
    role: "PARENT",
  }));

  ({ token: parentBToken } = await registerVerifiedUser({
    fullName: "Parent B",
    email: "parent-b@test.com",
    phone: "0911111102",
    role: "PARENT",
  }));

  ({ token: parentCToken } = await registerVerifiedUser({
    fullName: "Parent C",
    email: "parent-c@test.com",
    phone: "0911111103",
    role: "PARENT",
  }));

  ({ token: adminAToken, user: { id: adminAId } } = await registerVerifiedUser({
    fullName: "Admin A",
    email: "admin-a@test.com",
    phone: "0911111104",
    role: "SCHOOL_ADMIN",
  }));

  ({ token: adminBToken } = await registerVerifiedUser({
    fullName: "Admin B",
    email: "admin-b@test.com",
    phone: "0911111105",
    role: "SCHOOL_ADMIN",
  }));

  ({ token: moeToken } = await registerVerifiedUser({
    fullName: "MoE Officer",
    email: "moe@test.com",
    phone: "0911111106",
    role: "MOE_OFFICER",
  }));

  // --- Create fixture schools via API ---------------------------------------
  const create = async (token, body) => {
    const res = await request(app)
      .post("/api/schools")
      .set("Authorization", `Bearer ${token}`)
      .send(body);
    if (res.statusCode !== 201) {
      throw new Error(
        `school create failed (${res.statusCode}): ${JSON.stringify(res.body)}`
      );
    }
    return res.body.school.id;
  };

  schoolA1Id = await create(adminAToken, {
    schoolName: "Phase4 School A1",
    address: "Addis Ababa",
    contactEmail: "a1@test.com",
    contactPhone: "0911000001",
    curriculum: "LOCAL",
    tuitionFee: 5000,
    latitude: 9.0,
    longitude: 38.7,
  });

  schoolA2Id = await create(adminAToken, {
    schoolName: "Phase4 School A2",
    address: "Addis Ababa",
    contactEmail: "a2@test.com",
    contactPhone: "0911000002",
    curriculum: "INTERNATIONAL",
    tuitionFee: 15000,
    latitude: 9.05,
    longitude: 38.75,
  });

  schoolB1Id = await create(adminBToken, {
    schoolName: "Phase4 School B1",
    address: "Bahir Dar",
    contactEmail: "b1@test.com",
    contactPhone: "0911000003",
    curriculum: "LOCAL",
    tuitionFee: 8000,
    latitude: 11.6,
    longitude: 37.4,
  });

});

afterAll(async () => {
  await db.$disconnect();
});

// ---------------------------------------------------------------------------
// Subsystem 1: Follow / Subscribe
// ---------------------------------------------------------------------------
describe("Phase 4 — follow/subscribe", () => {
  it("PARENT follows a school and shows up in /api/me/follows", async () => {
    const res = await request(app)
      .post(`/api/schools/${schoolA1Id}/follow`)
      .set("Authorization", `Bearer ${parentAToken}`);
    expect(res.statusCode).toBe(201);
    expect(res.body.subscription.school.id).toBe(schoolA1Id);

    const list = await request(app)
      .get("/api/me/follows")
      .set("Authorization", `Bearer ${parentAToken}`);
    expect(list.statusCode).toBe(200);
    expect(list.body.data.map((s) => s.school.id)).toContain(schoolA1Id);
    expect(list.body.meta.total).toBe(1);
  });

  it("duplicate follow returns 409 CONFLICT", async () => {
    const res = await request(app)
      .post(`/api/schools/${schoolA1Id}/follow`)
      .set("Authorization", `Bearer ${parentAToken}`);
    expect(res.statusCode).toBe(409);
    expect(res.body.code).toBe("CONFLICT");
  });

  it("follow against unknown school returns 404", async () => {
    const res = await request(app)
      .post(`/api/schools/999999/follow`)
      .set("Authorization", `Bearer ${parentAToken}`);
    expect(res.statusCode).toBe(404);
  });

  it("non-PARENT cannot follow (403)", async () => {
    const res = await request(app)
      .post(`/api/schools/${schoolA1Id}/follow`)
      .set("Authorization", `Bearer ${adminAToken}`);
    expect(res.statusCode).toBe(403);
  });

  it("follower count is exposed on GET /api/schools/:id", async () => {
    const res = await request(app).get(`/api/schools/${schoolA1Id}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.school.followerCount).toBe(1);
  });

  it("unfollow removes the subscription; second unfollow is 404", async () => {
    const ok = await request(app)
      .delete(`/api/schools/${schoolA1Id}/follow`)
      .set("Authorization", `Bearer ${parentAToken}`);
    expect(ok.statusCode).toBe(200);

    const again = await request(app)
      .delete(`/api/schools/${schoolA1Id}/follow`)
      .set("Authorization", `Bearer ${parentAToken}`);
    expect(again.statusCode).toBe(404);

    const detail = await request(app).get(`/api/schools/${schoolA1Id}`);
    expect(detail.body.school.followerCount).toBe(0);
  });
});

// ---------------------------------------------------------------------------
// Subsystem 2: Comparison
// ---------------------------------------------------------------------------
describe("Phase 4 — comparison", () => {
  let comparisonId;

  it("rejects fewer than 2 schools (400)", async () => {
    const res = await request(app)
      .post("/api/comparisons")
      .set("Authorization", `Bearer ${parentAToken}`)
      .send({ schoolIds: [schoolA1Id] });
    expect(res.statusCode).toBe(400);
  });

  it("rejects more than 5 schools (400)", async () => {
    const res = await request(app)
      .post("/api/comparisons")
      .set("Authorization", `Bearer ${parentAToken}`)
      .send({ schoolIds: [1, 2, 3, 4, 5, 6] });
    expect(res.statusCode).toBe(400);
  });

  it("rejects duplicate school ids (400)", async () => {
    const res = await request(app)
      .post("/api/comparisons")
      .set("Authorization", `Bearer ${parentAToken}`)
      .send({ schoolIds: [schoolA1Id, schoolA1Id] });
    expect(res.statusCode).toBe(400);
  });

  it("returns 404 when one of the school ids does not exist", async () => {
    const res = await request(app)
      .post("/api/comparisons")
      .set("Authorization", `Bearer ${parentAToken}`)
      .send({ schoolIds: [schoolA1Id, 999999] });
    expect(res.statusCode).toBe(404);
  });

  it("PARENT can create a comparison of 2..5 schools", async () => {
    const res = await request(app)
      .post("/api/comparisons")
      .set("Authorization", `Bearer ${parentAToken}`)
      .send({
        schoolIds: [schoolA1Id, schoolA2Id, schoolB1Id],
        metrics: ["curriculum", "tuitionFee"],
      });
    expect(res.statusCode).toBe(201);
    expect(res.body.comparison.schools).toHaveLength(3);
    expect(res.body.comparison.metrics).toEqual([
      "curriculum",
      "tuitionFee",
    ]);
    comparisonId = res.body.comparison.id;
  });

  it("non-PARENT (SCHOOL_ADMIN) cannot create comparisons (403)", async () => {
    const res = await request(app)
      .post("/api/comparisons")
      .set("Authorization", `Bearer ${adminAToken}`)
      .send({ schoolIds: [schoolA1Id, schoolA2Id] });
    expect(res.statusCode).toBe(403);
  });

  it("GET /api/comparisons returns only the caller's comparisons", async () => {
    const res = await request(app)
      .get("/api/comparisons")
      .set("Authorization", `Bearer ${parentAToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.data.every((c) => c.id === comparisonId)).toBe(true);
  });

  it("another parent cannot read someone else's comparison (403)", async () => {
    const res = await request(app)
      .get(`/api/comparisons/${comparisonId}`)
      .set("Authorization", `Bearer ${parentBToken}`);
    expect(res.statusCode).toBe(403);
  });

  it("owner can fetch their comparison (200)", async () => {
    const res = await request(app)
      .get(`/api/comparisons/${comparisonId}`)
      .set("Authorization", `Bearer ${parentAToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.comparison.schools).toHaveLength(3);
  });

  it("owner can delete their comparison; second delete is 404", async () => {
    const ok = await request(app)
      .delete(`/api/comparisons/${comparisonId}`)
      .set("Authorization", `Bearer ${parentAToken}`);
    expect(ok.statusCode).toBe(200);

    const again = await request(app)
      .delete(`/api/comparisons/${comparisonId}`)
      .set("Authorization", `Bearer ${parentAToken}`);
    expect(again.statusCode).toBe(404);
  });
});

// ---------------------------------------------------------------------------
// Subsystem 3: Targeted announcement fan-out
// ---------------------------------------------------------------------------
describe("Phase 4 — targeted announcement fan-out", () => {
  beforeAll(async () => {
    // ParentA follows school A1; parentB follows school B1; parentC follows nothing.
    // Wipe any leftover Phase4-follow notifications so assertions count only
    // the rows produced by this describe block.
    await db.subscription.deleteMany();
    await db.notification.deleteMany();

    await request(app)
      .post(`/api/schools/${schoolA1Id}/follow`)
      .set("Authorization", `Bearer ${parentAToken}`);
    await request(app)
      .post(`/api/schools/${schoolB1Id}/follow`)
      .set("Authorization", `Bearer ${parentBToken}`);
  });

  it("SCHOOL_ADMIN announcement notifies only that school's subscribers", async () => {
    const res = await request(app)
      .post("/api/announcements/school")
      .set("Authorization", `Bearer ${adminAToken}`)
      .send({
        title: "Term break notice",
        content: "School A1 will close for term break next week.",
        category: "POLICY",
        urgencyLevel: "NORMAL",
        schoolId: schoolA1Id,
      });
    expect(res.statusCode).toBe(201);
    expect(res.body.announcement.schoolId).toBe(schoolA1Id);

    // Only parentA follows A1, so exactly one notification should fan out.
    const totalForThisAnnouncement = await db.notification.count({
      where: { sourceId: res.body.announcement.id },
    });
    expect(totalForThisAnnouncement).toBe(1);

    const sentToParentA = await db.notification.findFirst({
      where: {
        sourceId: res.body.announcement.id,
        recipientId: parentAId,
      },
    });
    expect(sentToParentA).not.toBeNull();
  });

  it("SCHOOL_ADMIN cannot post for a school they do not own (403)", async () => {
    const res = await request(app)
      .post("/api/announcements/school")
      .set("Authorization", `Bearer ${adminAToken}`)
      .send({
        title: "Sneaky",
        content: "Trying to post for someone else's school",
        category: "OTHER",
        urgencyLevel: "NORMAL",
        schoolId: schoolB1Id,
      });
    expect(res.statusCode).toBe(403);
  });

  it("SCHOOL_ADMIN announcement without schoolId is rejected (400)", async () => {
    const res = await request(app)
      .post("/api/announcements/school")
      .set("Authorization", `Bearer ${adminAToken}`)
      .send({
        title: "No school id",
        content: "missing schoolId on purpose",
        category: "OTHER",
        urgencyLevel: "NORMAL",
      });
    // Service throws ValidationError -> 400.
    expect(res.statusCode).toBe(400);
  });

  it("MOE announcement fans out to ALL parents", async () => {
    const res = await request(app)
      .post("/api/announcements/moe")
      .set("Authorization", `Bearer ${moeToken}`)
      .send({
        title: "Ministry update",
        content: "Nation-wide curriculum update",
        category: "POLICY",
        urgencyLevel: "HIGH",
      });
    expect(res.statusCode).toBe(201);
    expect(res.body.announcement.schoolId).toBeNull();

    const totalParents = await db.user.count({ where: { role: "PARENT" } });
    const fanned = await db.notification.count({
      where: { sourceId: res.body.announcement.id },
    });
    expect(fanned).toBe(totalParents);
  });
});

// ---------------------------------------------------------------------------
// Subsystem 4: Proximity search
// ---------------------------------------------------------------------------
describe("Phase 4 — proximity search", () => {
  it("returns only schools within radiusKm and sorts by distance", async () => {
    // From (9.0, 38.7) with 50km radius: A1 + A2 are nearby; B1 is ~500km away.
    const res = await request(app).get(
      "/api/schools?near=9.0,38.7&radiusKm=50&limit=50"
    );
    expect(res.statusCode).toBe(200);
    const ids = res.body.data.map((s) => s.id);
    expect(ids).toContain(schoolA1Id);
    expect(ids).toContain(schoolA2Id);
    expect(ids).not.toContain(schoolB1Id);

    // Sorted ascending by distance
    const distances = res.body.data.map((s) => s.distanceKm);
    const sorted = [...distances].sort((a, b) => a - b);
    expect(distances).toEqual(sorted);
  });

  it("widening the radius pulls in distant schools", async () => {
    const res = await request(app).get(
      "/api/schools?near=9.0,38.7&radiusKm=1000&limit=50"
    );
    expect(res.statusCode).toBe(200);
    const ids = res.body.data.map((s) => s.id);
    expect(ids).toContain(schoolB1Id);
  });

  it("composes with curriculum filter", async () => {
    const res = await request(app).get(
      "/api/schools?near=9.0,38.7&radiusKm=50&curriculum=INTERNATIONAL&limit=50"
    );
    expect(res.statusCode).toBe(200);
    const ids = res.body.data.map((s) => s.id);
    expect(ids).toContain(schoolA2Id);
    expect(ids).not.toContain(schoolA1Id);
  });

  it("rejects malformed `near` (400)", async () => {
    const res = await request(app).get("/api/schools?near=not-a-coord");
    expect(res.statusCode).toBe(400);
  });

  it("rejects out-of-range latitude (400)", async () => {
    const res = await request(app).get(
      "/api/schools?near=200,38.7&radiusKm=10"
    );
    expect(res.statusCode).toBe(400);
  });

  it("non-proximity listing still works (no near=)", async () => {
    const res = await request(app).get("/api/schools?limit=50");
    expect(res.statusCode).toBe(200);
    expect(res.body.data.length).toBeGreaterThanOrEqual(3);
  });
});
