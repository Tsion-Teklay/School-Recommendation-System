import request from "supertest";
import app from "../app.js";
import { db } from "../config/db.js";
import { cleanDatabase } from "./utils/cleanup.js";
import { registerVerifiedUser } from "./utils/auth.js";

let moeToken;
let adminToken;
let announcementId;

beforeAll(async () => {
  // Use the central utility to wipe all tables in the correct order
  await cleanDatabase();

  ({ token: moeToken } = await registerVerifiedUser({
    fullName: "MOE User",
    email: "moe@test.com",
    phone: "0910000000",
    role: "MOE_OFFICER",
  }));

  ({ token: adminToken } = await registerVerifiedUser({
    fullName: "Admin User",
    email: "admin@test.com",
    phone: "0920000000",
    role: "SCHOOL_ADMIN",
  }));
});

afterAll(async () => {
  await db.$disconnect();
});

describe("Announcement API", () => {
  it("should create announcement (MOE)", async () => {
    const res = await request(app)
      .post("/api/announcements")
      .set("Authorization", `Bearer ${moeToken}`)
      .send({
        title: "Important Update",
        content: "School policy changed",
        category: "POLICY",
        urgencyLevel: "HIGH",
      });

    expect(res.statusCode).toBe(201);
    expect(res.body.announcement).toHaveProperty("id");

    announcementId = res.body.announcement.id;
  });

  it("should get all announcements", async () => {
    const res = await request(app).get("/api/announcements");

    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body.data)).toBe(true);
  });

  it("should filter by category", async () => {
    const res = await request(app).get(
      "/api/announcements?category=POLICY"
    );

    expect(res.statusCode).toBe(200);
  });

  it("should update own announcement", async () => {
    const res = await request(app)
      .put(`/api/announcements/${announcementId}`)
      .set("Authorization", `Bearer ${moeToken}`)
      .send({ title: "Updated Title" });

    expect(res.statusCode).toBe(200);
    expect(res.body.announcement.title).toBe("Updated Title");
  });

  it("should NOT update others announcement", async () => {
    const res = await request(app)
      .put(`/api/announcements/${announcementId}`)
      .set("Authorization", `Bearer ${adminToken}`)
      .send({ title: "Hack" });

    expect(res.statusCode).toBe(403);
  });

  it("should delete own announcement", async () => {
    const res = await request(app)
      .delete(`/api/announcements/${announcementId}`)
      .set("Authorization", `Bearer ${moeToken}`);

    expect(res.statusCode).toBe(200);
  });
});
