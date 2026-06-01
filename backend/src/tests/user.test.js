import request from "supertest";
import app from "../app.js";
import { db } from "../config/db.js";
import { cleanDatabase } from "./utils/cleanup.js";
import { registerVerifiedUser } from "./utils/auth.js";

let token;
let userId;

beforeAll(async () => {
  await cleanDatabase();
  const result = await registerVerifiedUser({
    fullName: "Me Myself",
    email: "me@test.com",
    phone: "+251911000100",
    role: "PARENT",
  });
  token = result.token;
  userId = result.user.id;
});

afterAll(async () => {
  await db.$disconnect();
});

describe("GET /api/users/me", () => {
  it("401 without JWT", async () => {
    const res = await request(app).get("/api/users/me");
    expect(res.statusCode).toBe(401);
  });

  it("200 with JWT and no sensitive fields", async () => {
    const res = await request(app)
      .get("/api/users/me")
      .set("Authorization", `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.user.email).toBe("me@test.com");
    expect(res.body.user.password).toBeUndefined();
    expect(res.body.user.emailVerificationToken).toBeUndefined();
    expect(res.body.user.emailVerified).toBe(true);
  });
});

describe("PUT /api/users/me", () => {
  it("rejects empty body (Zod refinement)", async () => {
    const res = await request(app)
      .put("/api/users/me")
      .set("Authorization", `Bearer ${token}`)
      .send({});
    expect(res.statusCode).toBe(400);
  });

  it("updates fullName + phone", async () => {
    const res = await request(app)
      .put("/api/users/me")
      .set("Authorization", `Bearer ${token}`)
      .send({ fullName: "Me Renamed", phone: "+251911000199" });
    expect(res.statusCode).toBe(200);
    expect(res.body.user.fullName).toBe("Me Renamed");
    expect(res.body.user.phone).toBe("+251911000199");
  });

  it("ignores fields outside the whitelist", async () => {
    const res = await request(app)
      .put("/api/users/me")
      .set("Authorization", `Bearer ${token}`)
      .send({ fullName: "Safe Name", email: "hijack@test.com", role: "MODERATOR" });
    expect(res.statusCode).toBe(200);
    const row = await db.user.findUnique({ where: { id: userId } });
    expect(row.email).toBe("me@test.com");
    expect(row.role).toBe("PARENT");
  });
});

describe("POST /api/users/me/deactivate", () => {
  it("deactivates the account and blocks subsequent login", async () => {
    const res = await request(app)
      .post("/api/users/me/deactivate")
      .set("Authorization", `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.user.accountStatus).toBe("DEACTIVATED");

    const login = await request(app)
      .post("/api/auth/login")
      .send({ email: "me@test.com", password: "123456" });
    expect(login.statusCode).toBe(401);
    expect(login.body.error).toMatch(/deactivated/i);
  });
});
