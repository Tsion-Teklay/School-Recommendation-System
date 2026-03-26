import request from "supertest";
import app from "../app.js";
import { db } from "../config/db.js";
import { cleanDatabase } from "./utils/cleanup.js";

let token;
let validSchoolId;

beforeAll(async () => {
  await cleanDatabase();

  // 1. Create a School Admin
  const adminReg = await request(app).post("/api/auth/register").send({
    fullName: "Admin",
    email: "admin@test.com",
    phone: "0911223344",
    password: "123456",
    role: "SCHOOL_ADMIN",
  });

  const adminLogin = await request(app).post("/api/auth/login").send({
    email: "admin@test.com",
    password: "123456",
  });

  // 2. Create a School so analytics has a target
  const schoolRes = await request(app)
    .post("/api/schools")
    .set("Authorization", `Bearer ${adminLogin.body.token}`)
    .send({
      schoolName: "Data School",
      address: "Addis",
      contactEmail: "data@school.com",
      contactPhone: "0910000000",
      curriculum: "LOCAL",
      tuitionFee: 5000,
      latitude: 9.0,
      longitude: 38.0,
    });
  
  validSchoolId = schoolRes.body.school.id;

  // 3. Register MOE Officer for the actual test
  await request(app).post("/api/auth/register").send({
    fullName: "MOE",
    email: "moe2@test.com",
    phone: "0910000001",
    password: "123456",
    role: "MOE_OFFICER",
  });

  const login = await request(app).post("/api/auth/login").send({
    email: "moe2@test.com",
    password: "123456",
  });

  token = login.body.token;
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