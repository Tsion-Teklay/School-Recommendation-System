import request from "supertest";
import app from "../app.js";
import { db } from "../config/db.js";
import { cleanDatabase } from "./utils/cleanup.js"; // 1. Import the utility

let token;

beforeAll(async () => {
  // 2. Use the central utility instead of manual deletes
  await cleanDatabase();

  await request(app).post("/api/auth/register").send({
    fullName: "User",
    email: "notif@test.com",
    phone: "0910000000",
    password: "123456",
    role: "PARENT",
  });

  const login = await request(app).post("/api/auth/login").send({
    email: "notif@test.com",
    password: "123456",
  });

  token = login.body.token;
});

afterAll(async () => {
  await db.$disconnect();
});

describe("Notification API", () => {
  it("should get my notifications", async () => {
    const res = await request(app)
      .get("/api/notifications")
      .set("Authorization", `Bearer ${token}`);

    expect(res.statusCode).toBe(200);
    // Since we just cleared the DB, this will return an empty array []
    // which still passes the Array.isArray check.
    expect(Array.isArray(res.body.data)).toBe(true);
  });
});