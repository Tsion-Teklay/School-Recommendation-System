import request from "supertest";
import app from "../app.js";
import { db } from "../config/db.js";
import { cleanDatabase } from "./utils/cleanup.js";

let userToken;
let moderatorToken;
let reportId;

beforeAll(async () => {
  // Use the central utility to wipe all tables in the correct order
  // This is critical for clearing the Report and ModeratorAction tables
  await cleanDatabase();

  // Normal User
  await request(app).post("/api/auth/register").send({
    fullName: "User",
    email: "user@test.com",
    phone: "0911111111",
    password: "123456",
    role: "PARENT",
  });

  const userLogin = await request(app).post("/api/auth/login").send({
    email: "user@test.com",
    password: "123456",
  });

  userToken = userLogin.body.token;

  // Moderator
  await request(app).post("/api/auth/register").send({
    fullName: "Moderator",
    email: "mod@test.com",
    phone: "0922222222",
    password: "123456",
    role: "MODERATOR",
  });

  const modLogin = await request(app).post("/api/auth/login").send({
    email: "mod@test.com",
    password: "123456",
  });

  moderatorToken = modLogin.body.token;
});

afterAll(async () => {
  await db.$disconnect();
});

describe("Report System", () => {
  it("should create report", async () => {
    const res = await request(app)
      .post("/api/reports")
      .set("Authorization", `Bearer ${userToken}`)
      .send({
        targetType: "SCHOOL",
        targetId: 1,
        reason: "Incorrect info",
      });

    expect(res.statusCode).toBe(201);
    reportId = res.body.report.id;
  });

  it("should NOT allow unauthenticated report", async () => {
    const res = await request(app).post("/api/reports").send({
      targetType: "SCHOOL",
      targetId: 1,
      reason: "Spam",
    });

    expect(res.statusCode).toBe(401);
  });

  it("should NOT allow normal user to view reports", async () => {
    const res = await request(app)
      .get("/api/reports")
      .set("Authorization", `Bearer ${userToken}`);

    expect(res.statusCode).toBe(403);
  });

  it("should allow moderator to view reports", async () => {
    const res = await request(app)
      .get("/api/reports")
      .set("Authorization", `Bearer ${moderatorToken}`);

    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body.data)).toBe(true);
  });

  it("should allow moderator to take action", async () => {
    const res = await request(app)
      .post(`/api/reports/${reportId}/action`)
      .set("Authorization", `Bearer ${moderatorToken}`)
      .send({
        actionType: "REVIEWED",
        notes: "Checked and noted",
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.action).toHaveProperty("id");
  });

  it("should NOT allow normal user to take action", async () => {
    const res = await request(app)
      .post(`/api/reports/${reportId}/action`)
      .set("Authorization", `Bearer ${userToken}`)
      .send({
        actionType: "HACK",
      });

    expect(res.statusCode).toBe(403);
  });
});