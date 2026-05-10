import request from "supertest";
import app from "../app.js";
import { db } from "../config/db.js";
import { cleanDatabase } from "./utils/cleanup.js";

beforeAll(async () => {
  await cleanDatabase();
});

afterAll(async () => {
  await db.$disconnect();
});

describe("Phase 10: phone-based register + login", () => {
  it("rejects registration with neither email nor phone", async () => {
    const res = await request(app).post("/api/auth/register").send({
      fullName: "No Identifier",
      password: "hunter22",
      role: "PARENT",
    });
    expect(res.statusCode).toBe(400);
    expect(res.body.code).toBe("VALIDATION_ERROR");
  });

  it("registers a phone-only user and auto-verifies them", async () => {
    const res = await request(app).post("/api/auth/register").send({
      fullName: "Phone Only",
      phone: "0911999001",
      password: "hunter22",
      role: "PARENT",
    });
    expect(res.statusCode).toBe(201);
    // Phone-only signups have no email channel — backend stores a sentinel
    // address so the unique-email index isn't violated. Verify the placeholder
    // is opaque and the account is treated as already-verified.
    expect(res.body.user.email).toMatch(/@placeholder\.invalid$/);
    expect(res.body.user.phone).toBe("0911999001");
    expect(res.body.user.emailVerified).toBe(true);
    expect(res.body.token).toBeUndefined();
  });

  it("logs in by phone using the new identifier field", async () => {
    const res = await request(app)
      .post("/api/auth/login")
      .send({ identifier: "0911999001", password: "hunter22" });
    expect(res.statusCode).toBe(200);
    expect(res.body.token).toBeTruthy();
    expect(res.body.user.phone).toBe("0911999001");
  });

  it("returns 401 for unknown phone (no enumeration)", async () => {
    const res = await request(app)
      .post("/api/auth/login")
      .send({ identifier: "0911000000", password: "hunter22" });
    expect(res.statusCode).toBe(401);
    expect(res.body.code).toBe("UNAUTHORIZED");
  });

  it("returns 409 on duplicate phone", async () => {
    const res = await request(app).post("/api/auth/register").send({
      fullName: "Phone Dup",
      phone: "0911999001",
      password: "hunter22",
      role: "PARENT",
    });
    expect(res.statusCode).toBe(409);
    expect(res.body.code).toBe("CONFLICT");
  });

  it("still accepts the legacy `email` field at login (back-compat)", async () => {
    const email = "legacy.login@test.com";
    await request(app).post("/api/auth/register").send({
      fullName: "Legacy Login",
      email,
      password: "hunter22",
      role: "PARENT",
    });
    await db.user.update({
      where: { email },
      data: { emailVerified: true, emailVerificationToken: null },
    });

    const res = await request(app)
      .post("/api/auth/login")
      .send({ email, password: "hunter22" });
    expect(res.statusCode).toBe(200);
    expect(res.body.token).toBeTruthy();
  });

  it("logs in by email via the new identifier field", async () => {
    const res = await request(app)
      .post("/api/auth/login")
      .send({ identifier: "legacy.login@test.com", password: "hunter22" });
    expect(res.statusCode).toBe(200);
    expect(res.body.token).toBeTruthy();
  });
});

describe("Phase 10: preferences screen (home pin + criteria)", () => {
  let phoneOnlyToken;
  let existingParentToken;

  beforeAll(async () => {
    // Phone-only parent — no Parent row yet, must supply home pin to bootstrap.
    const phoneReg = await request(app).post("/api/auth/register").send({
      fullName: "Phone Parent",
      phone: "0922000010",
      password: "hunter22",
      role: "PARENT",
    });
    expect(phoneReg.statusCode).toBe(201);
    const phoneLogin = await request(app)
      .post("/api/auth/login")
      .send({ identifier: "0922000010", password: "hunter22" });
    phoneOnlyToken = phoneLogin.body.token;

    // Email parent who already has a Parent row — exercises the update branch.
    const email = "existing.parent@test.com";
    await request(app).post("/api/auth/register").send({
      fullName: "Existing Parent",
      email,
      password: "hunter22",
      role: "PARENT",
    });
    const userRow = await db.user.update({
      where: { email },
      data: { emailVerified: true, emailVerificationToken: null },
    });
    await db.parent.create({
      data: {
        userId: userRow.id,
        address: "Addis Ababa",
        latitude: 9.0,
        longitude: 38.7,
      },
    });
    const existingLogin = await request(app)
      .post("/api/auth/login")
      .send({ email, password: "hunter22" });
    existingParentToken = existingLogin.body.token;
  });

  it("GET /api/preferences/me returns nulls for a fresh parent", async () => {
    const res = await request(app)
      .get("/api/preferences/me")
      .set("Authorization", `Bearer ${phoneOnlyToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.preference.minBudget).toBeNull();
    expect(res.body.preference.address).toBeNull();
    expect(res.body.preference.latitude).toBeNull();
  });

  it("rejects first-time POST without home pin", async () => {
    const res = await request(app)
      .post("/api/preferences")
      .set("Authorization", `Bearer ${phoneOnlyToken}`)
      .send({ minBudget: 1000, maxBudget: 5000, curriculum: "LOCAL" });
    expect(res.statusCode).toBe(400);
    expect(res.body.code).toBe("VALIDATION_ERROR");
  });

  it("rejects lat-without-lng (schema-level paired-fields refine)", async () => {
    const res = await request(app)
      .post("/api/preferences")
      .set("Authorization", `Bearer ${phoneOnlyToken}`)
      .send({
        address: "Somewhere",
        latitude: 9.0,
        // no longitude
        minBudget: 1000,
      });
    expect(res.statusCode).toBe(400);
    expect(res.body.code).toBe("VALIDATION_ERROR");
  });

  it("first-time POST creates the Parent row + Preference row atomically", async () => {
    const res = await request(app)
      .post("/api/preferences")
      .set("Authorization", `Bearer ${phoneOnlyToken}`)
      .send({
        minBudget: 1500,
        maxBudget: 6000,
        curriculum: "INTERNATIONAL",
        distance: 12,
        address: "Bole, Addis Ababa",
        latitude: 9.0,
        longitude: 38.75,
      });
    expect(res.statusCode).toBe(200);
    expect(Number(res.body.preference.maxBudget)).toBe(6000);

    const got = await request(app)
      .get("/api/preferences/me")
      .set("Authorization", `Bearer ${phoneOnlyToken}`);
    expect(got.statusCode).toBe(200);
    expect(got.body.preference.curriculum).toBe("INTERNATIONAL");
    expect(got.body.preference.address).toBe("Bole, Addis Ababa");
    expect(Number(got.body.preference.latitude)).toBeCloseTo(9.0, 5);
    expect(Number(got.body.preference.longitude)).toBeCloseTo(38.75, 5);
  });

  it("subsequent POST without home pin updates only the criteria", async () => {
    const res = await request(app)
      .post("/api/preferences")
      .set("Authorization", `Bearer ${existingParentToken}`)
      .send({ minBudget: 3000, maxBudget: 9000, curriculum: "LOCAL", distance: 25 });
    expect(res.statusCode).toBe(200);

    const got = await request(app)
      .get("/api/preferences/me")
      .set("Authorization", `Bearer ${existingParentToken}`);
    expect(Number(got.body.preference.maxBudget)).toBe(9000);
    // Address must NOT have been wiped to null on a partial update.
    expect(got.body.preference.address).toBe("Addis Ababa");
  });

  it("PARENT role required (SCHOOL_ADMIN gets 403)", async () => {
    const email = "admin.p10@test.local";
    await request(app).post("/api/auth/register").send({
      fullName: "School Admin",
      email,
      password: "hunter22",
      role: "SCHOOL_ADMIN",
    });
    await db.user.update({
      where: { email },
      data: { emailVerified: true, emailVerificationToken: null },
    });
    const login = await request(app)
      .post("/api/auth/login")
      .send({ email, password: "hunter22" });

    const res = await request(app)
      .post("/api/preferences")
      .set("Authorization", `Bearer ${login.body.token}`)
      .send({ minBudget: 1000 });
    expect(res.statusCode).toBe(403);
  });
});
