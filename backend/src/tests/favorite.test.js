import request from "supertest";
import app from "../app.js";
import { db } from "../config/db.js";

let parentToken;
let schoolId;

beforeAll(async () => {
  // 1. DELETE IN CORRECT ORDER (Deepest children first)
  await db.preference.deleteMany(); // Added: This is what was causing your fail
  await db.favorite.deleteMany();
  await db.school.deleteMany();
  await db.parent.deleteMany();
  await db.user.deleteMany();

  // 2. Create parent
  await request(app).post("/api/auth/register").send({
    fullName: "Parent User",
    email: "fav@test.com",
    phone: "0955555555",
    password: "123456",
    role: "PARENT",
  });

  const login = await request(app).post("/api/auth/login").send({
    email: "fav@test.com",
    password: "123456",
  });

  parentToken = login.body.token;
  const parentId = login.body.user.id;

  // IMPORTANT: Manually create parent record so favorites can link to it
  await db.parent.create({
    data: {
      userId: parentId,
      address: "Addis",
      latitude: 9.0,
      longitude: 38.0
    }
  });

  // 3. Create school (need admin)
  await request(app).post("/api/auth/register").send({
    fullName: "Admin",
    email: "adminfav@test.com",
    phone: "0966666666",
    password: "123456",
    role: "SCHOOL_ADMIN",
  });

  const adminLogin = await request(app).post("/api/auth/login").send({
    email: "adminfav@test.com",
    password: "123456",
  });

  const schoolRes = await request(app)
    .post("/api/schools")
    .set("Authorization", `Bearer ${adminLogin.body.token}`)
    .send({
      schoolName: "Fav School",
      address: "Addis",
      contactEmail: "fav@school.com",
      contactPhone: "0910000000",
      curriculum: "LOCAL",
      tuitionFee: 3000,
      latitude: 9.0,
      longitude: 38.0,
    });

  schoolId = schoolRes.body.school.id;
});

afterAll(async () => {
  await db.$disconnect();
});

describe("Favorites API", () => {
  it("should add favorite", async () => {
    const res = await request(app)
      .post(`/api/favorites/${schoolId}`)
      .set("Authorization", `Bearer ${parentToken}`);

    if (res.statusCode !== 201) console.log("Add Favorite Error:", res.body);
    expect(res.statusCode).toBe(201);
  });

  it("should get favorites", async () => {
    const res = await request(app)
      .get("/api/favorites")
      .set("Authorization", `Bearer ${parentToken}`);

    expect(res.statusCode).toBe(200);
    // Ensure the data key exists based on your controller pattern
    expect(Array.isArray(res.body.data)).toBe(true);
  });

  it("should remove favorite", async () => {
    const res = await request(app)
      .delete(`/api/favorites/${schoolId}`)
      .set("Authorization", `Bearer ${parentToken}`);

    expect(res.statusCode).toBe(200);
  });
});