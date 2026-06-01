import request from "supertest";
import app from "../app.js";
import { db } from "../config/db.js";
import { cleanDatabase } from "./utils/cleanup.js";
import { registerVerifiedUser } from "./utils/auth.js";

let parentToken;
let otherParentToken;
let schoolId;
let reviewId;

beforeAll(async () => {
  // Use the central utility for a complete, order-safe wipe
  await cleanDatabase();

  // 1. Parent 1 + manual parent profile
  const p1 = await registerVerifiedUser({
    fullName: "Parent One",
    email: "parent1@test.com",
    phone: "+251910000001",
    role: "PARENT",
  });
  parentToken = p1.token;
  await db.parent.create({
    data: { userId: p1.user.id, latitude: 9.0, longitude: 38.0 },
  });

  // 2. Parent 2 + manual parent profile
  const p2 = await registerVerifiedUser({
    fullName: "Parent Two",
    email: "parent2@test.com",
    phone: "+251910000002",
    role: "PARENT",
  });
  otherParentToken = p2.token;
  await db.parent.create({
    data: { userId: p2.user.id, latitude: 9.0, longitude: 38.0 },
  });

  // 3. School admin + school
  const admin = await registerVerifiedUser({
    fullName: "Admin",
    email: "admin@test.com",
    phone: "+251910000003",
    role: "SCHOOL_ADMIN",
  });
  const schoolRes = await request(app)
    .post("/api/schools")
    .set("Authorization", `Bearer ${admin.token}`)
    .send({
      schoolName: "Review School",
      address: "Addis",
      contactEmail: "review@school.com",
      contactPhone: "+251910000000",
      curriculum: "LOCAL",
      tuitionFee: 4000,
      latitude: 9.0,
      longitude: 38.0,
    });
  schoolId = schoolRes.body.school.id;
});

afterAll(async () => {
  await db.$disconnect();
});

describe("Review API", () => {
  it("should create a review", async () => {
    const res = await request(app)
      .post(`/api/reviews/${schoolId}`)
      .set("Authorization", `Bearer ${parentToken}`)
      .send({
        rating: 5,
        comment: "Great school",
        categoryTag: "TEACHING_QUALITY",
      });

    if (res.statusCode !== 201) console.log("Create Error:", res.body);
    expect(res.statusCode).toBe(201);
    expect(res.body.review).toHaveProperty("id");
    reviewId = res.body.review.id;
  });

  it("should get reviews for a school", async () => {
    const res = await request(app).get(`/api/reviews/school/${schoolId}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body.data)).toBe(true);
    expect(res.body.data.length).toBeGreaterThan(0);
  });

  it("should update own review", async () => {
    const res = await request(app)
      .put(`/api/reviews/${reviewId}`)
      .set("Authorization", `Bearer ${parentToken}`)
      .send({ rating: 4, comment: "Updated review" });

    expect(res.statusCode).toBe(200);
    expect(res.body.review.rating).toBe(4);
  });

  it("should NOT update another user's review", async () => {
    const res = await request(app)
      .put(`/api/reviews/${reviewId}`)
      .set("Authorization", `Bearer ${otherParentToken}`)
      .send({ rating: 1 });

    expect(res.statusCode).toBe(403);
  });

  it("should delete own review", async () => {
    const res = await request(app)
      .delete(`/api/reviews/${reviewId}`)
      .set("Authorization", `Bearer ${parentToken}`);

    expect(res.statusCode).toBe(200);
  });
});
