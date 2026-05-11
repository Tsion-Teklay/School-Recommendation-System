import request from "supertest";
import app from "../app.js";
import { db } from "../config/db.js";
import { cleanDatabase } from "./utils/cleanup.js";
import { registerVerifiedUser } from "./utils/auth.js";

let token;

beforeAll(async () => {
  // 2. Use the central utility instead of manual deletes
  await cleanDatabase();

  ({ token } = await registerVerifiedUser({
    fullName: "User",
    email: "notif@test.com",
    phone: "0910000000",
    role: "PARENT",
  }));
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
