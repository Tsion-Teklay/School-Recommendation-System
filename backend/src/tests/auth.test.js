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

describe("Auth: register + email verification", () => {
  const email = "verify@test.com";

  it("rejects a weak password via Zod", async () => {
    const res = await request(app).post("/api/auth/register").send({
      fullName: "Short PW",
      email: "shortpw@test.com",
      password: "123", // min 6
      role: "PARENT",
    });
    expect(res.statusCode).toBe(400);
    expect(res.body.code).toBe("VALIDATION_ERROR");
  });

  it("creates an unverified user on register", async () => {
    const res = await request(app).post("/api/auth/register").send({
      fullName: "Verify Me",
      email,
      phone: "0911000001",
      password: "hunter22",
      role: "PARENT",
    });

    expect(res.statusCode).toBe(201);
    expect(res.body.user.emailVerified).toBe(false);
    // Token should never be returned in the response.
    expect(res.body.user.emailVerificationToken).toBeUndefined();
    expect(res.body.token).toBeUndefined();

    const row = await db.user.findUnique({ where: { email } });
    expect(row.emailVerified).toBe(false);
    expect(row.emailVerificationToken).toBeTruthy();
  });

  it("returns 409 on duplicate email", async () => {
    const res = await request(app).post("/api/auth/register").send({
      fullName: "Dup",
      email,
      phone: "0911000099",
      password: "hunter22",
      role: "PARENT",
    });
    expect(res.statusCode).toBe(409);
    expect(res.body.code).toBe("CONFLICT");
  });

  it("blocks login before email verification with EMAIL_NOT_VERIFIED", async () => {
    const res = await request(app).post("/api/auth/login").send({
      email,
      password: "hunter22",
    });
    expect(res.statusCode).toBe(401);
    expect(res.body.code).toBe("EMAIL_NOT_VERIFIED");
  });

  it("verifies email with a valid token", async () => {
    const row = await db.user.findUnique({ where: { email } });
    const res = await request(app)
      .post("/api/auth/verify-email")
      .send({ token: row.emailVerificationToken });

    expect(res.statusCode).toBe(200);
    const after = await db.user.findUnique({ where: { email } });
    expect(after.emailVerified).toBe(true);
    expect(after.emailVerificationToken).toBeNull();
  });

  it("lets the verified user log in", async () => {
    const res = await request(app).post("/api/auth/login").send({
      email,
      password: "hunter22",
    });
    expect(res.statusCode).toBe(200);
    expect(res.body.token).toBeTruthy();
  });

  it("rejects an invalid verification token", async () => {
    const res = await request(app)
      .post("/api/auth/verify-email")
      .send({ token: "not-a-real-token" });
    expect(res.statusCode).toBe(400);
  });

  it("resend-verification returns 200 even for unknown emails (no enumeration)", async () => {
    const res = await request(app)
      .post("/api/auth/resend-verification")
      .send({ email: "ghost@nowhere.test" });
    expect(res.statusCode).toBe(200);
  });
});

describe("Auth: forgot + reset password", () => {
  const email = "reset@test.com";

  beforeAll(async () => {
    await request(app).post("/api/auth/register").send({
      fullName: "Reset User",
      email,
      phone: "0911000002",
      password: "oldpass1",
      role: "PARENT",
    });
    await db.user.update({
      where: { email },
      data: { emailVerified: true, emailVerificationToken: null },
    });
  });

  it("forgot-password returns 200 for unknown email (no enumeration)", async () => {
    const res = await request(app)
      .post("/api/auth/forgot-password")
      .send({ email: "nobody@nowhere.test" });
    expect(res.statusCode).toBe(200);
  });

  it("forgot-password writes a reset token for a real account", async () => {
    const res = await request(app)
      .post("/api/auth/forgot-password")
      .send({ email });
    expect(res.statusCode).toBe(200);

    const row = await db.user.findUnique({ where: { email } });
    expect(row.passwordResetToken).toBeTruthy();
    expect(row.passwordResetExpires.getTime()).toBeGreaterThan(Date.now());
  });

  it("reset-password rejects invalid token", async () => {
    const res = await request(app)
      .post("/api/auth/reset-password")
      .send({ token: "bogus", newPassword: "newpass1" });
    expect(res.statusCode).toBe(400);
  });

  it("reset-password swaps the password and clears the token", async () => {
    const before = await db.user.findUnique({ where: { email } });
    const res = await request(app)
      .post("/api/auth/reset-password")
      .send({ token: before.passwordResetToken, newPassword: "newpass1" });
    expect(res.statusCode).toBe(200);

    const after = await db.user.findUnique({ where: { email } });
    expect(after.passwordResetToken).toBeNull();

    // Old password no longer works, new one does.
    const oldLogin = await request(app)
      .post("/api/auth/login")
      .send({ email, password: "oldpass1" });
    expect(oldLogin.statusCode).toBe(401);

    const newLogin = await request(app)
      .post("/api/auth/login")
      .send({ email, password: "newpass1" });
    expect(newLogin.statusCode).toBe(200);
  });
});

describe("Auth: change password (authenticated)", () => {
  const email = "change@test.com";
  let token;

  beforeAll(async () => {
    await request(app).post("/api/auth/register").send({
      fullName: "Change PW",
      email,
      phone: "0911000003",
      password: "origpass1",
      role: "PARENT",
    });
    await db.user.update({
      where: { email },
      data: { emailVerified: true, emailVerificationToken: null },
    });
    const login = await request(app)
      .post("/api/auth/login")
      .send({ email, password: "origpass1" });
    token = login.body.token;
  });

  it("requires auth", async () => {
    const res = await request(app)
      .post("/api/auth/change-password")
      .send({ currentPassword: "origpass1", newPassword: "newpass2" });
    expect(res.statusCode).toBe(401);
  });

  it("rejects wrong currentPassword", async () => {
    const res = await request(app)
      .post("/api/auth/change-password")
      .set("Authorization", `Bearer ${token}`)
      .send({ currentPassword: "wrong", newPassword: "newpass2" });
    expect(res.statusCode).toBe(401);
  });

  it("rejects when new password equals current", async () => {
    const res = await request(app)
      .post("/api/auth/change-password")
      .set("Authorization", `Bearer ${token}`)
      .send({ currentPassword: "origpass1", newPassword: "origpass1" });
    expect(res.statusCode).toBe(400);
  });

  it("changes password and lets user log in with the new one", async () => {
    const res = await request(app)
      .post("/api/auth/change-password")
      .set("Authorization", `Bearer ${token}`)
      .send({ currentPassword: "origpass1", newPassword: "newpass2" });
    expect(res.statusCode).toBe(200);

    const newLogin = await request(app)
      .post("/api/auth/login")
      .send({ email, password: "newpass2" });
    expect(newLogin.statusCode).toBe(200);
  });
});
