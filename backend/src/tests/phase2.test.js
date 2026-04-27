/**
 * Phase 2 — schema-hardening regression tests.
 *
 * Covers the behaviours added by the Phase 2 migration:
 *   1. School.rating + reviewCount auto-recompute on review CRUD
 *   2. ReviewCategoryTag accepts the new FACILITIES + AFFORDABILITY values
 *      and rejects unknown values via Zod
 *   3. Subscription model with @@unique([parentId, schoolId])
 *   4. VerificationRequest model with status enum default
 *   5. Notification.sourceType is now an enum (REVIEW value works)
 */
import request from "supertest";
import app from "../app.js";
import { db } from "../config/db.js";
import { cleanDatabase } from "./utils/cleanup.js";
import { registerVerifiedUser } from "./utils/auth.js";

let adminToken;
let parent1Token;
let parent1Id;
let parent2Token;
let parent2Id;
let schoolId;
let schoolAdminId;

beforeAll(async () => {
  await cleanDatabase();

  const admin = await registerVerifiedUser({
    fullName: "Phase2 Admin",
    email: "phase2.admin@test.com",
    phone: "0950000001",
    role: "SCHOOL_ADMIN",
  });
  adminToken = admin.token;
  schoolAdminId = admin.user.id;

  const p1 = await registerVerifiedUser({
    fullName: "Phase2 P1",
    email: "phase2.p1@test.com",
    phone: "0950000002",
    role: "PARENT",
  });
  parent1Token = p1.token;
  parent1Id = p1.user.id;
  await db.parent.create({
    data: { userId: p1.user.id, address: "Addis", latitude: 9.0, longitude: 38.0 },
  });

  const p2 = await registerVerifiedUser({
    fullName: "Phase2 P2",
    email: "phase2.p2@test.com",
    phone: "0950000003",
    role: "PARENT",
  });
  parent2Token = p2.token;
  parent2Id = p2.user.id;
  await db.parent.create({
    data: { userId: p2.user.id, address: "Addis", latitude: 9.0, longitude: 38.0 },
  });

  const schoolRes = await request(app)
    .post("/api/schools")
    .set("Authorization", `Bearer ${adminToken}`)
    .send({
      schoolName: "Phase2 School",
      address: "Addis",
      contactEmail: "phase2@school.com",
      contactPhone: "0950000099",
      curriculum: "LOCAL",
      tuitionFee: 4000,
      latitude: 9.0,
      longitude: 38.0,
    });
  expect(schoolRes.statusCode).toBe(201);
  schoolId = schoolRes.body.school.id;
});

afterAll(async () => {
  await db.$disconnect();
});

describe("School.rating + reviewCount auto-recompute", () => {
  it("a freshly created school has rating=0 and reviewCount=0", async () => {
    const row = await db.school.findUnique({ where: { id: schoolId } });
    expect(Number(row.rating)).toBe(0);
    expect(row.reviewCount).toBe(0);
  });

  it("creating a review pushes rating + count to the school row", async () => {
    const res = await request(app)
      .post(`/api/reviews/${schoolId}`)
      .set("Authorization", `Bearer ${parent1Token}`)
      .send({ rating: 5, comment: "Excellent", categoryTag: "TEACHING_QUALITY" });
    expect(res.statusCode).toBe(201);

    const row = await db.school.findUnique({ where: { id: schoolId } });
    expect(Number(row.rating)).toBe(5);
    expect(row.reviewCount).toBe(1);
  });

  it("a second review averages to (5 + 3) / 2 = 4.00", async () => {
    const res = await request(app)
      .post(`/api/reviews/${schoolId}`)
      .set("Authorization", `Bearer ${parent2Token}`)
      .send({ rating: 3, comment: "Average", categoryTag: "FACILITIES" });
    expect(res.statusCode).toBe(201);

    const row = await db.school.findUnique({ where: { id: schoolId } });
    expect(Number(row.rating)).toBe(4);
    expect(row.reviewCount).toBe(2);
  });

  it("updating a review's rating refreshes the aggregate", async () => {
    const review = await db.review.findFirst({
      where: { schoolId, parentId: parent2Id },
    });
    const res = await request(app)
      .put(`/api/reviews/${review.id}`)
      .set("Authorization", `Bearer ${parent2Token}`)
      .send({ rating: 1 });
    expect(res.statusCode).toBe(200);

    const row = await db.school.findUnique({ where: { id: schoolId } });
    // (5 + 1) / 2 = 3.00
    expect(Number(row.rating)).toBe(3);
    expect(row.reviewCount).toBe(2);
  });

  it("deleting a review decrements the count and re-averages", async () => {
    const review = await db.review.findFirst({
      where: { schoolId, parentId: parent2Id },
    });
    const res = await request(app)
      .delete(`/api/reviews/${review.id}`)
      .set("Authorization", `Bearer ${parent2Token}`);
    expect(res.statusCode).toBe(200);

    const row = await db.school.findUnique({ where: { id: schoolId } });
    expect(Number(row.rating)).toBe(5);
    expect(row.reviewCount).toBe(1);
  });

  it("deleting the last review resets rating to 0", async () => {
    const review = await db.review.findFirst({
      where: { schoolId, parentId: parent1Id },
    });
    const res = await request(app)
      .delete(`/api/reviews/${review.id}`)
      .set("Authorization", `Bearer ${parent1Token}`);
    expect(res.statusCode).toBe(200);

    const row = await db.school.findUnique({ where: { id: schoolId } });
    expect(Number(row.rating)).toBe(0);
    expect(row.reviewCount).toBe(0);
  });
});

describe("ReviewCategoryTag enum (Phase 2 expansion)", () => {
  it("accepts AFFORDABILITY", async () => {
    const res = await request(app)
      .post(`/api/reviews/${schoolId}`)
      .set("Authorization", `Bearer ${parent1Token}`)
      .send({ rating: 4, comment: "Affordable", categoryTag: "AFFORDABILITY" });
    expect(res.statusCode).toBe(201);
    expect(res.body.review.categoryTag).toBe("AFFORDABILITY");

    // Cleanup so later assertions stay isolated.
    await db.review.delete({ where: { id: res.body.review.id } });
  });

  it("rejects unknown categoryTag with 400 VALIDATION_ERROR", async () => {
    const res = await request(app)
      .post(`/api/reviews/${schoolId}`)
      .set("Authorization", `Bearer ${parent1Token}`)
      .send({ rating: 4, categoryTag: "TOTALLY_MADE_UP" });
    expect(res.statusCode).toBe(400);
    expect(res.body.code).toBe("VALIDATION_ERROR");
  });
});

describe("Subscription model — schema only (endpoints are Phase 4)", () => {
  it("creates a (parent, school) row", async () => {
    const sub = await db.subscription.create({
      data: { parentId: parent1Id, schoolId },
    });
    expect(sub.id).toBeGreaterThan(0);
  });

  it("rejects a duplicate (parent, school) pair via the composite unique index", async () => {
    await expect(
      db.subscription.create({
        data: { parentId: parent1Id, schoolId },
      })
    ).rejects.toThrow();
  });

  it("a different parent can subscribe to the same school", async () => {
    const sub = await db.subscription.create({
      data: { parentId: parent2Id, schoolId },
    });
    expect(sub.id).toBeGreaterThan(0);

    const all = await db.subscription.findMany({ where: { schoolId } });
    expect(all).toHaveLength(2);
  });
});

describe("VerificationRequest model — schema only (endpoints are Phase 3)", () => {
  it("creates a request that defaults to PENDING with documents stored as JSON", async () => {
    const req = await db.verificationRequest.create({
      data: {
        schoolId,
        submittedById: schoolAdminId,
        documents: ["/uploads/license.pdf", "/uploads/registration.pdf"],
        notes: "Please verify.",
      },
    });
    expect(req.status).toBe("PENDING");
    expect(Array.isArray(req.documents)).toBe(true);
    expect(req.documents).toHaveLength(2);
  });

  it("an MoE officer can transition the request to APPROVED with reviewer + reviewedAt", async () => {
    const moe = await registerVerifiedUser({
      fullName: "MoE Officer",
      email: "phase2.moe@test.com",
      phone: "0950000050",
      role: "MOE_OFFICER",
    });

    const before = await db.verificationRequest.findFirst({ where: { schoolId } });
    const updated = await db.verificationRequest.update({
      where: { id: before.id },
      data: {
        status: "APPROVED",
        reviewedById: moe.user.id,
        reviewedAt: new Date(),
        reviewNotes: "Documents look good.",
      },
    });
    expect(updated.status).toBe("APPROVED");
    expect(updated.reviewedById).toBe(moe.user.id);
    expect(updated.reviewedAt).toBeInstanceOf(Date);
  });
});

describe("Notification.sourceType is now an enum", () => {
  it("a REVIEW-sourced notification round-trips with the JS enum name", async () => {
    const notif = await db.notification.create({
      data: {
        recipientId: parent1Id,
        recipientType: "PARENT",
        message: "Your review was flagged.",
        sourceType: "REVIEW",
        sourceId: 1,
      },
    });
    expect(notif.sourceType).toBe("REVIEW");
  });
});
