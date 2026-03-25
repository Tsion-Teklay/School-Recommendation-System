import request from "supertest";
import app from "../app.js";
import { db } from "../config/db.js";

let parentToken;
let otherParentToken;
let schoolId;
let reviewId;

beforeAll(async () => {
  // 1. Correct Cleanup Order (Children -> Parents)
  await db.review.deleteMany();
  await db.preference.deleteMany();
  await db.favorite.deleteMany();
  await db.school.deleteMany();
  await db.parent.deleteMany();
  await db.user.deleteMany();

  // 2. Create Parent 1 + Manual Profile
  await request(app).post("/api/auth/register").send({
    fullName: "Parent One",
    email: "parent1@test.com",
    phone: "0910000001",
    password: "123456",
    role: "PARENT",
  });
  const login1 = await request(app).post("/api/auth/login").send({
    email: "parent1@test.com",
    password: "123456",
  });
  parentToken = login1.body.token;
  await db.parent.create({
    data: { userId: login1.body.user.id, address: "Addis", latitude: 9.0, longitude: 38.0 }
  });

  // 3. Create Parent 2 + Manual Profile
  await request(app).post("/api/auth/register").send({
    fullName: "Parent Two",
    email: "parent2@test.com",
    phone: "0910000002",
    password: "123456",
    role: "PARENT",
  });
  const login2 = await request(app).post("/api/auth/login").send({
    email: "parent2@test.com",
    password: "123456",
  });
  otherParentToken = login2.body.token;
  await db.parent.create({
    data: { userId: login2.body.user.id, address: "Addis", latitude: 9.0, longitude: 38.0 }
  });

  // 4. Create SCHOOL_ADMIN + school
  await request(app).post("/api/auth/register").send({
    fullName: "Admin",
    email: "admin@test.com",
    phone: "0910000003",
    password: "123456",
    role: "SCHOOL_ADMIN",
  });
  const adminLogin = await request(app).post("/api/auth/login").send({
    email: "admin@test.com",
    password: "123456",
  });
  const schoolRes = await request(app)
    .post("/api/schools")
    .set("Authorization", `Bearer ${adminLogin.body.token}`)
    .send({
      schoolName: "Review School",
      address: "Addis",
      contactEmail: "review@school.com",
      contactPhone: "0910000000",
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