import request from "supertest";
import app from "../app.js";
import { db } from "../config/db.js";

let parentToken;

beforeAll(async () => {
  // 1. Clean up to avoid "Unique Constraint" errors on re-run
  // Order matters: Delete children (preferences) before parents
  await db.review.deleteMany();      // Added
  await db.preference.deleteMany();
  await db.favorite.deleteMany();    // Added
  await db.school.deleteMany();      // This fixes the admin_id error!
  await db.parent.deleteMany();
  await db.user.deleteMany();

  // 2. Register a User
  await request(app).post("/api/auth/register").send({
    fullName: "Parent User",
    email: "parent2@test.com",
    phone: "0944444444",
    password: "123456",
    role: "PARENT",
  });

  // 3. Login to get the Token and User ID
  const login = await request(app).post("/api/auth/login").send({
    email: "parent2@test.com",
    password: "123456",
  });

  parentToken = login.body.token;
  const userId = login.body.user.id;

  // 4. MANUALLY CREATE PARENT PROFILE
  // This is the fix: Preference needs a row in 'parent' to exist first.
  await db.parent.create({
    data: {
      userId: userId,
      address: "Addis Ababa",
      latitude: 9.0331,
      longitude: 38.7501,
    },
  });
});

afterAll(async () => {
  await db.$disconnect();
});

describe("Preference API", () => {
  
  it("should create/update preference", async () => {
    const res = await request(app)
      .post("/api/preferences")
      .set("Authorization", `Bearer ${parentToken}`)
      .send({
        minBudget: 2000,
        maxBudget: 8000,
        curriculum: "LOCAL",
        distance: 10,
      });

    // Logging detailed error if the test fails
    if (res.statusCode !== 200 && res.statusCode !== 201) {
      console.log("Preference Creation Error Details:", JSON.stringify(res.body, null, 2));
    }

    // Checking for 200 (Updated) or 201 (Created)
    expect([200, 201]).toContain(res.statusCode); 
    
    // In your schema, the ID field is parentId
    expect(res.body.preference).toHaveProperty("parentId");
    expect(Number(res.body.preference.maxBudget)).toBe(8000);
  });

  it("should get my preference", async () => {
    const res = await request(app)
      .get("/api/preferences/me")
      .set("Authorization", `Bearer ${parentToken}`);

    if (res.statusCode !== 200) {
      console.log("Preference Fetch Error Details:", JSON.stringify(res.body, null, 2));
    }

    expect(res.statusCode).toBe(200);
    expect(res.body.preference).toHaveProperty("minBudget");
    expect(res.body.preference).toHaveProperty("curriculum", "LOCAL");
  });
});