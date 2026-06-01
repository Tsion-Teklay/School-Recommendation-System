import request from "supertest";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";

import app from "../app.js";
import { db } from "../config/db.js";
import { cleanDatabase } from "./utils/cleanup.js";
import { registerVerifiedUser } from "./utils/auth.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Reuse a tiny PNG fixture we generate on disk for each suite — keeps the
// test deterministic and avoids committing binary fixtures.
const FIXTURE_DIR = path.join(__dirname, "fixtures");
const FIXTURE_PDF = path.join(FIXTURE_DIR, "license.pdf");
const FIXTURE_PNG = path.join(FIXTURE_DIR, "stamp.png");
const FIXTURE_TXT = path.join(FIXTURE_DIR, "rejected.txt");

beforeAll(() => {
  fs.mkdirSync(FIXTURE_DIR, { recursive: true });
  // %PDF-1.4 magic bytes — multer keys on Content-Type, but content shouldn't
  // be empty for any tooling that pokes at the saved file.
  fs.writeFileSync(FIXTURE_PDF, "%PDF-1.4\n%fake\n%%EOF\n");
  fs.writeFileSync(
    FIXTURE_PNG,
    Buffer.from(
      "89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c4890000000a49444154789c63000100000005000101e21f3a000000000049454e44ae426082",
      "hex"
    )
  );
  fs.writeFileSync(FIXTURE_TXT, "not an allowed type\n");
});

afterAll(() => {
  fs.rmSync(FIXTURE_DIR, { recursive: true, force: true });
});

beforeEach(async () => {
  await cleanDatabase();
});

afterAll(async () => {
  await cleanDatabase();
  await db.$disconnect();
});

async function setupAdminWithSchool({ emailSuffix = "v" } = {}) {
  const { token, user } = await registerVerifiedUser({
    fullName: `Admin ${emailSuffix}`,
    email: `admin.${emailSuffix}@school.test`,
    phone: `+2519800${emailSuffix.padStart(5, "0").slice(-5)}`,
    role: "SCHOOL_ADMIN",
  });

  const schoolRes = await request(app)
    .post("/api/schools")
    .set("Authorization", `Bearer ${token}`)
    .send({
      schoolName: `School ${emailSuffix}`,
      address: "123 Main St",
      contactEmail: `contact.${emailSuffix}@school.test`,
      contactPhone: "+251911000000",
      curriculum: "LOCAL",
      tuitionFee: 12000,
      facilities: "library, lab",
      latitude: 9.0,
      longitude: 38.7,
    });

  expect(schoolRes.statusCode).toBe(201);
  return { token, user, school: schoolRes.body.school };
}

async function setupMoeOfficer({ emailSuffix = "moe" } = {}) {
  return registerVerifiedUser({
    fullName: `MoE Officer ${emailSuffix}`,
    email: `officer.${emailSuffix}@moe.test`,
    phone: `+2519700${emailSuffix.padStart(5, "0").slice(-5)}`,
    role: "MOE_OFFICER",
  });
}

describe("POST /api/schools/:schoolId/verification-requests", () => {
  test("SCHOOL_ADMIN owner can submit a PDF + PNG", async () => {
    const { token, school } = await setupAdminWithSchool();

    const res = await request(app)
      .post(`/api/schools/${school.id}/verification-requests`)
      .set("Authorization", `Bearer ${token}`)
      .field("notes", "Includes accreditation + tax license")
      .attach("documents", FIXTURE_PDF)
      .attach("documents", FIXTURE_PNG);

    expect(res.statusCode).toBe(201);
    expect(res.body.request.status).toBe("PENDING");
    expect(res.body.request.documents).toHaveLength(2);
    expect(res.body.request.documents[0].url).toMatch(/^\/uploads\/verification\//);
    expect(res.body.request.notes).toBe("Includes accreditation + tax license");

    // School itself stays PENDING until an MoE officer reviews.
    const stored = await db.school.findUnique({ where: { id: school.id } });
    expect(stored.verificationStatus).toBe("PENDING");
  });

  test("submitting without files returns 400 VALIDATION_ERROR", async () => {
    const { token, school } = await setupAdminWithSchool({ emailSuffix: "n" });

    const res = await request(app)
      .post(`/api/schools/${school.id}/verification-requests`)
      .set("Authorization", `Bearer ${token}`);

    expect(res.statusCode).toBe(400);
    expect(res.body.code).toBe("VALIDATION_ERROR");
  });

  test("rejects unsupported MIME type (txt) with 400", async () => {
    const { token, school } = await setupAdminWithSchool({ emailSuffix: "txt" });

    const res = await request(app)
      .post(`/api/schools/${school.id}/verification-requests`)
      .set("Authorization", `Bearer ${token}`)
      .attach("documents", FIXTURE_TXT);

    expect(res.statusCode).toBe(400);
    expect(res.body.code).toBe("VALIDATION_ERROR");
    expect(res.body.error).toMatch(/Unsupported file type/);
  });

  test("non-owner SCHOOL_ADMIN cannot submit for someone else's school", async () => {
    const { school } = await setupAdminWithSchool({ emailSuffix: "owner" });
    const { token: intruderToken } = await registerVerifiedUser({
      fullName: "Intruder Admin",
      email: "intruder@school.test",
      phone: "+251980111222",
      role: "SCHOOL_ADMIN",
    });

    const res = await request(app)
      .post(`/api/schools/${school.id}/verification-requests`)
      .set("Authorization", `Bearer ${intruderToken}`)
      .attach("documents", FIXTURE_PDF);

    expect(res.statusCode).toBe(403);
    expect(res.body.code).toBe("FORBIDDEN");
  });

  test("PARENT cannot submit (role gate)", async () => {
    const { school } = await setupAdminWithSchool({ emailSuffix: "p" });
    const { token: parentToken } = await registerVerifiedUser({
      fullName: "P. Arent",
      email: "parent@verify.test",
      phone: "+251980222333",
      role: "PARENT",
    });

    const res = await request(app)
      .post(`/api/schools/${school.id}/verification-requests`)
      .set("Authorization", `Bearer ${parentToken}`)
      .attach("documents", FIXTURE_PDF);

    expect(res.statusCode).toBe(403);
  });

  test("a second pending submission is rejected with 409 CONFLICT", async () => {
    const { token, school } = await setupAdminWithSchool({ emailSuffix: "dup" });

    await request(app)
      .post(`/api/schools/${school.id}/verification-requests`)
      .set("Authorization", `Bearer ${token}`)
      .attach("documents", FIXTURE_PDF)
      .expect(201);

    const res = await request(app)
      .post(`/api/schools/${school.id}/verification-requests`)
      .set("Authorization", `Bearer ${token}`)
      .attach("documents", FIXTURE_PDF);

    expect(res.statusCode).toBe(409);
    expect(res.body.code).toBe("CONFLICT");
  });
});

describe("GET /api/verification-requests", () => {
  test("MOE_OFFICER sees every request across all schools", async () => {
    const adminA = await setupAdminWithSchool({ emailSuffix: "A" });
    const adminB = await setupAdminWithSchool({ emailSuffix: "B" });

    await request(app)
      .post(`/api/schools/${adminA.school.id}/verification-requests`)
      .set("Authorization", `Bearer ${adminA.token}`)
      .attach("documents", FIXTURE_PDF)
      .expect(201);
    await request(app)
      .post(`/api/schools/${adminB.school.id}/verification-requests`)
      .set("Authorization", `Bearer ${adminB.token}`)
      .attach("documents", FIXTURE_PDF)
      .expect(201);

    const { token: officerToken } = await setupMoeOfficer();
    const res = await request(app)
      .get("/api/verification-requests")
      .set("Authorization", `Bearer ${officerToken}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.data).toHaveLength(2);
    expect(res.body.meta.total).toBe(2);
  });

  test("SCHOOL_ADMIN sees only requests for schools they own", async () => {
    const adminA = await setupAdminWithSchool({ emailSuffix: "X" });
    const adminB = await setupAdminWithSchool({ emailSuffix: "Y" });

    await request(app)
      .post(`/api/schools/${adminA.school.id}/verification-requests`)
      .set("Authorization", `Bearer ${adminA.token}`)
      .attach("documents", FIXTURE_PDF)
      .expect(201);
    await request(app)
      .post(`/api/schools/${adminB.school.id}/verification-requests`)
      .set("Authorization", `Bearer ${adminB.token}`)
      .attach("documents", FIXTURE_PDF)
      .expect(201);

    const res = await request(app)
      .get("/api/verification-requests")
      .set("Authorization", `Bearer ${adminA.token}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].school.id).toBe(adminA.school.id);
  });

  test("status filter narrows the list", async () => {
    const admin = await setupAdminWithSchool({ emailSuffix: "fs" });
    await request(app)
      .post(`/api/schools/${admin.school.id}/verification-requests`)
      .set("Authorization", `Bearer ${admin.token}`)
      .attach("documents", FIXTURE_PDF)
      .expect(201);

    const { token: officerToken } = await setupMoeOfficer();
    const empty = await request(app)
      .get("/api/verification-requests?status=APPROVED")
      .set("Authorization", `Bearer ${officerToken}`);
    expect(empty.body.data).toHaveLength(0);

    const pending = await request(app)
      .get("/api/verification-requests?status=PENDING")
      .set("Authorization", `Bearer ${officerToken}`);
    expect(pending.body.data).toHaveLength(1);
  });
});

describe("GET /api/verification-requests/:id", () => {
  test("owner SchoolAdmin and any MoE officer can fetch; outsiders get 403", async () => {
    const owner = await setupAdminWithSchool({ emailSuffix: "view" });
    const create = await request(app)
      .post(`/api/schools/${owner.school.id}/verification-requests`)
      .set("Authorization", `Bearer ${owner.token}`)
      .attach("documents", FIXTURE_PDF);
    const id = create.body.request.id;

    const ownerRes = await request(app)
      .get(`/api/verification-requests/${id}`)
      .set("Authorization", `Bearer ${owner.token}`);
    expect(ownerRes.statusCode).toBe(200);
    expect(ownerRes.body.request.id).toBe(id);

    const { token: officerToken } = await setupMoeOfficer();
    const officerRes = await request(app)
      .get(`/api/verification-requests/${id}`)
      .set("Authorization", `Bearer ${officerToken}`);
    expect(officerRes.statusCode).toBe(200);

    const { token: outsiderToken } = await registerVerifiedUser({
      fullName: "Other Admin",
      email: "other.admin@school.test",
      phone: "+251980333444",
      role: "SCHOOL_ADMIN",
    });
    const outsiderRes = await request(app)
      .get(`/api/verification-requests/${id}`)
      .set("Authorization", `Bearer ${outsiderToken}`);
    expect(outsiderRes.statusCode).toBe(403);
  });

  test("404 for unknown id", async () => {
    const { token } = await setupMoeOfficer();
    const res = await request(app)
      .get("/api/verification-requests/9999")
      .set("Authorization", `Bearer ${token}`);
    expect(res.statusCode).toBe(404);
  });
});

describe("POST /api/verification-requests/:id/review", () => {
  async function submitOne(emailSuffix) {
    const { token, school, user } = await setupAdminWithSchool({ emailSuffix });
    const create = await request(app)
      .post(`/api/schools/${school.id}/verification-requests`)
      .set("Authorization", `Bearer ${token}`)
      .attach("documents", FIXTURE_PDF);
    return { token, school, user, id: create.body.request.id };
  }

  test("APPROVED → school becomes VERIFIED + admin gets a SCHOOL notification", async () => {
    const { school, user } = await submitOne("approve");
    const { token: officerToken } = await setupMoeOfficer({ emailSuffix: "appr" });

    const res = await request(app)
      .post(`/api/verification-requests/${(await db.verificationRequest.findFirst({where: {schoolId: school.id}})).id}/review`)
      .set("Authorization", `Bearer ${officerToken}`)
      .send({ status: "APPROVED", reviewNotes: "All docs check out." });

    expect(res.statusCode).toBe(200);
    expect(res.body.request.status).toBe("APPROVED");
    expect(res.body.request.reviewNotes).toBe("All docs check out.");

    const updatedSchool = await db.school.findUnique({ where: { id: school.id } });
    expect(updatedSchool.verificationStatus).toBe("VERIFIED");

    const notif = await db.notification.findFirst({
      where: { recipientId: user.id, sourceType: "SCHOOL", sourceId: school.id },
    });
    expect(notif).not.toBeNull();
    expect(notif.message).toMatch(/verified by the Ministry/);
  });

  test("REJECTED → school becomes REJECTED + reviewNotes are surfaced in the notification", async () => {
    const { school, user } = await submitOne("reject");
    const { token: officerToken } = await setupMoeOfficer({ emailSuffix: "rej" });

    const id = (await db.verificationRequest.findFirst({ where: { schoolId: school.id } })).id;
    const res = await request(app)
      .post(`/api/verification-requests/${id}/review`)
      .set("Authorization", `Bearer ${officerToken}`)
      .send({ status: "REJECTED", reviewNotes: "License is expired." });

    expect(res.statusCode).toBe(200);
    expect(res.body.request.status).toBe("REJECTED");

    const updatedSchool = await db.school.findUnique({ where: { id: school.id } });
    expect(updatedSchool.verificationStatus).toBe("REJECTED");

    const notif = await db.notification.findFirst({
      where: { recipientId: user.id, sourceType: "SCHOOL", sourceId: school.id },
    });
    expect(notif.message).toMatch(/License is expired/);
  });

  test("non-MoE caller cannot review (403)", async () => {
    const { token, school } = await submitOne("forbid");
    const id = (await db.verificationRequest.findFirst({ where: { schoolId: school.id } })).id;

    const res = await request(app)
      .post(`/api/verification-requests/${id}/review`)
      .set("Authorization", `Bearer ${token}`) // SchoolAdmin owner
      .send({ status: "APPROVED" });

    expect(res.statusCode).toBe(403);
  });

  test("reviewing a non-PENDING request returns 409", async () => {
    const { school } = await submitOne("twice");
    const { token: officerToken } = await setupMoeOfficer({ emailSuffix: "twice" });
    const id = (await db.verificationRequest.findFirst({ where: { schoolId: school.id } })).id;

    await request(app)
      .post(`/api/verification-requests/${id}/review`)
      .set("Authorization", `Bearer ${officerToken}`)
      .send({ status: "APPROVED" })
      .expect(200);

    const res = await request(app)
      .post(`/api/verification-requests/${id}/review`)
      .set("Authorization", `Bearer ${officerToken}`)
      .send({ status: "REJECTED" });

    expect(res.statusCode).toBe(409);
    expect(res.body.code).toBe("CONFLICT");
  });

  test("Zod rejects unknown status with 400", async () => {
    const { school } = await submitOne("zod");
    const { token: officerToken } = await setupMoeOfficer({ emailSuffix: "zod" });
    const id = (await db.verificationRequest.findFirst({ where: { schoolId: school.id } })).id;

    const res = await request(app)
      .post(`/api/verification-requests/${id}/review`)
      .set("Authorization", `Bearer ${officerToken}`)
      .send({ status: "MAYBE" });

    expect(res.statusCode).toBe(400);
    expect(res.body.code).toBe("VALIDATION_ERROR");
  });
});

describe("Static /uploads", () => {
  test("uploaded file is fetchable read-only via /uploads URL", async () => {
    const { token, school } = await setupAdminWithSchool({ emailSuffix: "static" });
    const submitRes = await request(app)
      .post(`/api/schools/${school.id}/verification-requests`)
      .set("Authorization", `Bearer ${token}`)
      .attach("documents", FIXTURE_PDF);

    const url = submitRes.body.request.documents[0].url;
    expect(url.startsWith("/uploads/")).toBe(true);

    const res = await request(app).get(url);
    expect(res.statusCode).toBe(200);
    expect(res.headers["content-type"]).toMatch(/application\/pdf/);
  });
});
