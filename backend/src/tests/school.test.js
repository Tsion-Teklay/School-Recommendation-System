import request from "supertest";
import app from "../app.js";
import { db } from "../config/db.js";
import { cleanDatabase } from "./utils/cleanup.js";

let adminToken;
let otherAdminToken;
let parentToken;
let schoolId;

beforeAll(async () => {
  // Use the central utility to wipe the slate clean
  await cleanDatabase();

  // Create SCHOOL_ADMIN 1
  await request(app).post("/api/auth/register").send({
    fullName: "Admin One",
    email: "admin1@test.com",
    phone: "0911111111",
    password: "123456",
    role: "SCHOOL_ADMIN",
  });

  const login1 = await request(app).post("/api/auth/login").send({
    email: "admin1@test.com",
    password: "123456",
  });

  adminToken = login1.body.token;

  // Create SCHOOL_ADMIN 2
  await request(app).post("/api/auth/register").send({
    fullName: "Admin Two",
    email: "admin2@test.com",
    phone: "0922222222",
    password: "123456",
    role: "SCHOOL_ADMIN",
  });

  const login2 = await request(app).post("/api/auth/login").send({
    email: "admin2@test.com",
    password: "123456",
  });

  otherAdminToken = login2.body.token;

  // Create a PARENT for protected endpoints (e.g. /api/recommendations)
  await request(app).post("/api/auth/register").send({
    fullName: "Parent User",
    email: "parent@test.com",
    phone: "0933333333",
    password: "123456",
    role: "PARENT",
  });

  const parentLogin = await request(app).post("/api/auth/login").send({
    email: "parent@test.com",
    password: "123456",
  });

  parentToken = parentLogin.body.token;
});

afterAll(async () => {
  await db.$disconnect();
});

describe("School CRUD", () => {
  // ✅ CREATE
  it("should create a school", async () => {
    const res = await request(app)
      .post("/api/schools")
      .set("Authorization", `Bearer ${adminToken}`)
      .send({
        schoolName: "Test School",
        address: "Addis Ababa",
        contactEmail: "school@test.com",
        contactPhone: "0912345678",
        curriculum: "LOCAL", 
        tuitionFee: 5000,
        latitude: 9.0331,
        longitude: 38.7501 
      });

    if (res.statusCode !== 201) {
      console.log("Create Error Response:", res.body);
    }

    expect(res.statusCode).toBe(201);
    expect(res.body.school).toHaveProperty("id");

    schoolId = res.body.school.id;
  });

  // ❌ CREATE with wrong role
  it("should fail if not SCHOOL_ADMIN", async () => {
    const res = await request(app)
      .post("/api/schools")
      .set("Authorization", `Bearer ${parentToken}`)
      .send({
        schoolName: "Fail School",
        address: "Addis",
        contactEmail: "fail@test.com",
        contactPhone: "0988888888",
        curriculum: "LOCAL",
        tuitionFee: 3000,
        latitude: 9.0,
        longitude: 38.0
      });

    expect(res.statusCode).toBe(403);
  });

  // ✅ GET ALL & Search/Filter
  it("should get all schools", async () => {
    const res = await request(app).get("/api/schools");
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body.data)).toBe(true);
  });

  it("should filter by curriculum", async () => {
    const res = await request(app).get("/api/schools?curriculum=LOCAL");
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body.data)).toBe(true);
  });

  it("should search by school name", async () => {
    const res = await request(app).get("/api/schools?search=Test");
    expect(res.statusCode).toBe(200);
    expect(res.body.data.length).toBeGreaterThan(0);
  });

  it("should paginate results", async () => {
    const res = await request(app).get("/api/schools?page=1&limit=1");
    expect(res.statusCode).toBe(200);
    expect(res.body.data.length).toBeLessThanOrEqual(1);
    expect(res.body.meta).toHaveProperty("totalPages");
  });

  // 🎯 RECOMMENDATIONS
  it("should reject unauthenticated recommendation requests", async () => {
    const res = await request(app).get("/api/recommendations?curriculum=LOCAL");
    expect(res.statusCode).toBe(401);
  });

  it("should forbid non-parent users from getting recommendations", async () => {
    const res = await request(app)
      .get("/api/recommendations?curriculum=LOCAL")
      .set("Authorization", `Bearer ${adminToken}`);
    expect(res.statusCode).toBe(403);
  });

  it("should return recommended schools for a parent", async () => {
    const res = await request(app)
      .get("/api/recommendations?curriculum=LOCAL")
      .set("Authorization", `Bearer ${parentToken}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body.data)).toBe(true);
    // Results should have a calculated score
    expect(res.body.data[0]).toHaveProperty("score");
  });

  // ✅ UPDATE OWN
  it("should update own school", async () => {
    const res = await request(app)
      .put(`/api/schools/${schoolId}`)
      .set("Authorization", `Bearer ${adminToken}`)
      .send({ schoolName: "Updated School" });

    expect(res.statusCode).toBe(200);
    expect(res.body.school.schoolName).toBe("Updated School");
  });

  // ❌ UPDATE OTHER
  it("should NOT update other user's school", async () => {
    const res = await request(app)
      .put(`/api/schools/${schoolId}`)
      .set("Authorization", `Bearer ${otherAdminToken}`)
      .send({ schoolName: "Hack Attempt" });

    expect(res.statusCode).toBe(403);
  });

  // ❌ DELETE OTHER
  it("should NOT delete other user's school", async () => {
    const res = await request(app)
      .delete(`/api/schools/${schoolId}`)
      .set("Authorization", `Bearer ${otherAdminToken}`);

    expect(res.statusCode).toBe(403);
  });

  // ✅ DELETE OWN
  it("should delete own school", async () => {
    const res = await request(app)
      .delete(`/api/schools/${schoolId}`)
      .set("Authorization", `Bearer ${adminToken}`);

    expect(res.statusCode).toBe(200);
  });
});
