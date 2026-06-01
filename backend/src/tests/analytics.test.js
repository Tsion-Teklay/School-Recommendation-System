import request from "supertest";
import app from "../app.js";
import { db } from "../config/db.js";
import { cleanDatabase } from "./utils/cleanup.js";
import { registerVerifiedUser } from "./utils/auth.js";

let token;
let validSchoolId;

beforeAll(async () => {
  await cleanDatabase();

  // 1. Create a School Admin (verified)
  const admin = await registerVerifiedUser({
    fullName: "Admin",
    email: "admin@test.com",
    phone: "+251911223344",
    role: "SCHOOL_ADMIN",
  });

  // 2. Create a School so analytics has a target
  const schoolRes = await request(app)
    .post("/api/schools")
    .set("Authorization", `Bearer ${admin.token}`)
    .send({
      schoolName: "Data School",
      address: "Addis",
      contactEmail: "data@school.com",
      contactPhone: "+251910000000",
      curriculum: "LOCAL",
      tuitionFee: 5000,
      latitude: 9.0,
      longitude: 38.0,
    });
  
  validSchoolId = schoolRes.body.school.id;

  // 3. Register MOE Officer for the actual test (verified)
  ({ token } = await registerVerifiedUser({
    fullName: "MOE",
    email: "moe2@test.com",
    phone: "+251910000001",
    role: "MOE_OFFICER",
  }));
});

describe("Analytics API", () => {
  it("should create analytics", async () => {
  const res = await request(app)
    .post("/api/analytics")
    .set("Authorization", `Bearer ${token}`)
    .send({
      schoolId: validSchoolId,
      metricType: "PASS_RATE",
      metricValue: 85,
      academicYear: 2024,
      source: "MOE_ANNUAL_REPORT", // ✅ ADD THIS FIELD
    });

  expect(res.statusCode).toBe(201);
});
  
  it("should get dashboard", async () => {
    const res = await request(app)
      .get("/api/analytics/dashboard")
      .set("Authorization", `Bearer ${token}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.summary).toHaveProperty("totalSchools");
  });
});
