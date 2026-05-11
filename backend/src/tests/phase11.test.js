/**
 * Phase 11 — facility images, school filters (minRating + schoolLevel),
 * announcement image upload, and the announcements-feed extensions
 * (schoolId + followedOnly).
 *
 * Covers the new endpoints introduced in this phase. The other phases
 * already cover the underlying announcement / school CRUD; we only assert
 * the new behaviours here.
 */
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

const FIXTURE_DIR = path.join(__dirname, "fixtures");
const FIXTURE_PNG = path.join(FIXTURE_DIR, "image.png");
const FIXTURE_TXT = path.join(FIXTURE_DIR, "not-an-image.txt");

beforeAll(() => {
  fs.mkdirSync(FIXTURE_DIR, { recursive: true });
  // 1x1 PNG — same fixture the verification suite uses, copied here so the
  // suites can run independently without ordering assumptions.
  fs.writeFileSync(
    FIXTURE_PNG,
    Buffer.from(
      "89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c4890000000a49444154789c63000100000005000101e21f3a000000000049454e44ae426082",
      "hex"
    )
  );
  fs.writeFileSync(FIXTURE_TXT, "i am not an image\n");
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

// Phones must be globally unique across users (per the auth schema). Pad an
// incrementing counter into a 10-digit string so every fixture user gets a
// distinct phone regardless of what string the caller passes for emailSuffix.
let phoneSeq = 0;
function nextPhone() {
  phoneSeq += 1;
  return `091${String(phoneSeq).padStart(7, "0")}`;
}

async function setupAdminWithSchool({ emailSuffix = "fi", schoolLevel } = {}) {
  const { token, user } = await registerVerifiedUser({
    fullName: `Admin ${emailSuffix}`,
    email: `admin.${emailSuffix}.${phoneSeq + 1}@p11.test`,
    phone: nextPhone(),
    role: "SCHOOL_ADMIN",
  });

  const body = {
    schoolName: `Phase11 ${emailSuffix}`,
    address: "Addis",
    contactEmail: `contact.${emailSuffix}@p11.test`,
    contactPhone: "0911000000",
    curriculum: "LOCAL",
    tuitionFee: 5000,
    facilities: "library",
    latitude: 9.0,
    longitude: 38.7,
  };
  if (schoolLevel) body.schoolLevel = schoolLevel;

  const res = await request(app)
    .post("/api/schools")
    .set("Authorization", `Bearer ${token}`)
    .send(body);
  expect(res.statusCode).toBe(201);
  return { token, user, school: res.body.school };
}

async function setupParent(emailSuffix = "parent") {
  return registerVerifiedUser({
    fullName: `Parent ${emailSuffix}`,
    email: `parent.${emailSuffix}.${phoneSeq + 1}@p11.test`,
    phone: nextPhone(),
    role: "PARENT",
  });
}

describe("Phase 11 — facility images", () => {
  test("SCHOOL_ADMIN owner can upload, list reflects it, payload includes facilityImages", async () => {
    const { token, school } = await setupAdminWithSchool({ emailSuffix: "fa" });

    const uploadRes = await request(app)
      .post(`/api/schools/${school.id}/images`)
      .set("Authorization", `Bearer ${token}`)
      .attach("image", FIXTURE_PNG);
    expect(uploadRes.statusCode).toBe(201);
    expect(uploadRes.body.image.imageUrl).toMatch(/^\/uploads\/facility-images\//);
    expect(uploadRes.body.image.id).toEqual(expect.any(Number));

    // The GET /:id payload should include the new image.
    const detail = await request(app).get(`/api/schools/${school.id}`);
    expect(detail.statusCode).toBe(200);
    expect(detail.body.school.facilityImages).toHaveLength(1);
    expect(detail.body.school.facilityImages[0].imageUrl).toBe(
      uploadRes.body.image.imageUrl
    );

    // The dedicated list endpoint also works.
    const listRes = await request(app).get(`/api/schools/${school.id}/images`);
    expect(listRes.statusCode).toBe(200);
    expect(listRes.body.images).toHaveLength(1);
  });

  test("uploaded file is fetchable read-only via /uploads URL", async () => {
    const { token, school } = await setupAdminWithSchool({ emailSuffix: "st" });
    const uploadRes = await request(app)
      .post(`/api/schools/${school.id}/images`)
      .set("Authorization", `Bearer ${token}`)
      .attach("image", FIXTURE_PNG);
    const fileRes = await request(app).get(uploadRes.body.image.imageUrl);
    expect(fileRes.statusCode).toBe(200);
    expect(fileRes.headers["content-type"]).toMatch(/image\/png/);
  });

  test("non-image MIME (txt) rejected with 400", async () => {
    const { token, school } = await setupAdminWithSchool({ emailSuffix: "mi" });
    const res = await request(app)
      .post(`/api/schools/${school.id}/images`)
      .set("Authorization", `Bearer ${token}`)
      .attach("image", FIXTURE_TXT);
    expect(res.statusCode).toBe(400);
    expect(res.body.code).toBe("VALIDATION_ERROR");
    expect(res.body.error).toMatch(/Unsupported file type/);
  });

  test("missing file under field 'image' returns 400", async () => {
    const { token, school } = await setupAdminWithSchool({ emailSuffix: "no" });
    const res = await request(app)
      .post(`/api/schools/${school.id}/images`)
      .set("Authorization", `Bearer ${token}`);
    expect(res.statusCode).toBe(400);
  });

  test("non-owner SCHOOL_ADMIN cannot upload to someone else's school", async () => {
    const { school } = await setupAdminWithSchool({ emailSuffix: "ow" });
    const { token: intruderToken } = await setupAdminWithSchool({
      emailSuffix: "in",
    });
    const res = await request(app)
      .post(`/api/schools/${school.id}/images`)
      .set("Authorization", `Bearer ${intruderToken}`)
      .attach("image", FIXTURE_PNG);
    expect(res.statusCode).toBe(403);
    expect(res.body.code).toBe("FORBIDDEN");
  });

  test("PARENT cannot upload (role gate, 403)", async () => {
    const { school } = await setupAdminWithSchool({ emailSuffix: "pa" });
    const { token: parentToken } = await setupParent("imgp");
    const res = await request(app)
      .post(`/api/schools/${school.id}/images`)
      .set("Authorization", `Bearer ${parentToken}`)
      .attach("image", FIXTURE_PNG);
    expect(res.statusCode).toBe(403);
  });

  test("owner can delete their image; non-owner cannot", async () => {
    const { token, school } = await setupAdminWithSchool({ emailSuffix: "de" });
    const uploadRes = await request(app)
      .post(`/api/schools/${school.id}/images`)
      .set("Authorization", `Bearer ${token}`)
      .attach("image", FIXTURE_PNG);
    const imgId = uploadRes.body.image.id;

    const { token: intruderToken } = await setupAdminWithSchool({
      emailSuffix: "di",
    });
    const forbidden = await request(app)
      .delete(`/api/schools/${school.id}/images/${imgId}`)
      .set("Authorization", `Bearer ${intruderToken}`);
    expect(forbidden.statusCode).toBe(403);

    const okDel = await request(app)
      .delete(`/api/schools/${school.id}/images/${imgId}`)
      .set("Authorization", `Bearer ${token}`);
    expect(okDel.statusCode).toBe(200);

    const after = await request(app).get(`/api/schools/${school.id}`);
    expect(after.body.school.facilityImages).toHaveLength(0);
  });

  test("deleting an image that belongs to a different school returns 404", async () => {
    const { token, school } = await setupAdminWithSchool({ emailSuffix: "x1" });
    const { token: t2, school: s2 } = await setupAdminWithSchool({
      emailSuffix: "x2",
    });
    const upload = await request(app)
      .post(`/api/schools/${s2.id}/images`)
      .set("Authorization", `Bearer ${t2}`)
      .attach("image", FIXTURE_PNG);
    const wrongPath = await request(app)
      .delete(`/api/schools/${school.id}/images/${upload.body.image.id}`)
      .set("Authorization", `Bearer ${token}`);
    expect(wrongPath.statusCode).toBe(404);
  });
});

describe("Phase 11 — school list filters: minRating + schoolLevel", () => {
  let adminToken;
  let lowSchoolId;
  let highSchoolId;
  let primaryId;
  let secondaryId;

  beforeEach(async () => {
    const admin = await setupAdminWithSchool({
      emailSuffix: "fl",
      schoolLevel: "PRIMARY",
    });
    adminToken = admin.token;
    primaryId = admin.school.id;

    // We need rating values set. The Phase 2 trigger keeps `rating` in sync
    // with reviews; for the filter we just write directly to the column.
    const lowRated = await db.school.update({
      where: { id: primaryId },
      data: { rating: "2.5", reviewCount: 4 },
    });
    lowSchoolId = lowRated.id;

    const secondary = await setupAdminWithSchool({
      emailSuffix: "sd",
      schoolLevel: "SECONDARY",
    });
    secondaryId = secondary.school.id;
    const highRated = await db.school.update({
      where: { id: secondaryId },
      data: { rating: "4.7", reviewCount: 8 },
    });
    highSchoolId = highRated.id;
  });

  test("schoolLevel filter narrows to PRIMARY only", async () => {
    const res = await request(app).get("/api/schools?schoolLevel=PRIMARY");
    expect(res.statusCode).toBe(200);
    const ids = res.body.data.map((s) => s.id);
    expect(ids).toContain(primaryId);
    expect(ids).not.toContain(secondaryId);
  });

  test("schoolLevel=SECONDARY surfaces only SECONDARY schools", async () => {
    const res = await request(app).get("/api/schools?schoolLevel=SECONDARY");
    expect(res.body.data.map((s) => s.id)).toEqual([secondaryId]);
  });

  test("invalid schoolLevel rejected with 400", async () => {
    const res = await request(app).get("/api/schools?schoolLevel=GRAD_SCHOOL");
    expect(res.statusCode).toBe(400);
    expect(res.body.code).toBe("VALIDATION_ERROR");
  });

  test("minRating=4 returns only the high-rated school", async () => {
    const res = await request(app).get("/api/schools?minRating=4");
    expect(res.statusCode).toBe(200);
    expect(res.body.data.map((s) => s.id)).toEqual([highSchoolId]);
  });

  test("minRating=0 returns everything (treats 0 as 'no filter')", async () => {
    const res = await request(app).get("/api/schools?minRating=0");
    expect(res.body.data.length).toBeGreaterThanOrEqual(2);
  });

  test("create + update with explicit schoolLevel persists the field", async () => {
    const { token, school } = await setupAdminWithSchool({
      emailSuffix: "pl",
      schoolLevel: "PRE_PRIMARY",
    });
    expect(school.schoolLevel).toBe("PRE_PRIMARY");

    const upd = await request(app)
      .put(`/api/schools/${school.id}`)
      .set("Authorization", `Bearer ${token}`)
      .send({ schoolLevel: "PRIMARY" });
    expect(upd.statusCode).toBe(200);
    expect(upd.body.school.schoolLevel).toBe("PRIMARY");
  });
});

describe("Phase 11 — announcements: image upload + schoolId/followedOnly", () => {
  async function postAnnouncement({ token, schoolId, title = "hi" }) {
    const res = await request(app)
      .post("/api/announcements")
      .set("Authorization", `Bearer ${token}`)
      .send({
        title,
        content: "body",
        category: "OTHER",
        urgencyLevel: "NORMAL",
        ...(schoolId ? { schoolId } : {}),
      });
    expect(res.statusCode).toBe(201);
    return res.body.announcement;
  }

  test("publisher (SCHOOL_ADMIN) can attach + clear an image; non-owner cannot", async () => {
    const { token, school } = await setupAdminWithSchool({ emailSuffix: "ai" });
    const ann = await postAnnouncement({ token, schoolId: school.id });

    const upload = await request(app)
      .post(`/api/announcements/${ann.id}/image`)
      .set("Authorization", `Bearer ${token}`)
      .attach("image", FIXTURE_PNG);
    expect(upload.statusCode).toBe(200);
    expect(upload.body.announcement.imgUrl).toMatch(
      /^\/uploads\/announcement-images\//
    );

    // The GET endpoint should now expose imgUrl on the row.
    const fetched = await request(app).get(`/api/announcements/${ann.id}`);
    expect(fetched.body.announcement.imgUrl).toBe(
      upload.body.announcement.imgUrl
    );

    // A different SCHOOL_ADMIN cannot mutate this announcement.
    const { token: otherToken } = await setupAdminWithSchool({
      emailSuffix: "ao",
    });
    const blocked = await request(app)
      .post(`/api/announcements/${ann.id}/image`)
      .set("Authorization", `Bearer ${otherToken}`)
      .attach("image", FIXTURE_PNG);
    expect(blocked.statusCode).toBe(403);

    // Owner can clear it.
    const clear = await request(app)
      .delete(`/api/announcements/${ann.id}/image`)
      .set("Authorization", `Bearer ${token}`);
    expect(clear.statusCode).toBe(200);
    expect(clear.body.announcement.imgUrl).toBeNull();
  });

  test("non-image MIME rejected with 400", async () => {
    const { token, school } = await setupAdminWithSchool({ emailSuffix: "an" });
    const ann = await postAnnouncement({ token, schoolId: school.id });
    const res = await request(app)
      .post(`/api/announcements/${ann.id}/image`)
      .set("Authorization", `Bearer ${token}`)
      .attach("image", FIXTURE_TXT);
    expect(res.statusCode).toBe(400);
  });

  test("PARENT cannot attach images (role gate, 403)", async () => {
    const { token: adminToken, school } = await setupAdminWithSchool({
      emailSuffix: "ap",
    });
    const ann = await postAnnouncement({ token: adminToken, schoolId: school.id });
    const { token: parentToken } = await setupParent("annp");
    const res = await request(app)
      .post(`/api/announcements/${ann.id}/image`)
      .set("Authorization", `Bearer ${parentToken}`)
      .attach("image", FIXTURE_PNG);
    expect(res.statusCode).toBe(403);
  });

  test("?schoolId narrows the feed to that school, newest first", async () => {
    const { token: tA, school: sA } = await setupAdminWithSchool({
      emailSuffix: "fa",
    });
    const { token: tB, school: sB } = await setupAdminWithSchool({
      emailSuffix: "fb",
    });

    const a1 = await postAnnouncement({ token: tA, schoolId: sA.id, title: "A1" });
    await new Promise((r) => setTimeout(r, 50));
    const a2 = await postAnnouncement({ token: tA, schoolId: sA.id, title: "A2" });
    await postAnnouncement({ token: tB, schoolId: sB.id, title: "B" });

    const res = await request(app).get(`/api/announcements?schoolId=${sA.id}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.data.map((x) => x.title)).toEqual(["A2", "A1"]);
    expect(res.body.data[0].school?.id).toBe(sA.id);
  });

  test("followedOnly=true returns only posts from schools the parent follows", async () => {
    const { token: tA, school: sA } = await setupAdminWithSchool({
      emailSuffix: "fA",
    });
    const { token: tB, school: sB } = await setupAdminWithSchool({
      emailSuffix: "fB",
    });
    await postAnnouncement({ token: tA, schoolId: sA.id, title: "FromA" });
    await postAnnouncement({ token: tB, schoolId: sB.id, title: "FromB" });

    const { token: parentToken, user: parent } = await setupParent("foll");
    // Parent follows only school A.
    await db.subscription.create({
      data: { parentId: parent.id, schoolId: sA.id },
    });

    const res = await request(app)
      .get("/api/announcements?followedOnly=true")
      .set("Authorization", `Bearer ${parentToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.data.map((x) => x.title)).toEqual(["FromA"]);

    // No follows → empty.
    const { token: emptyToken } = await setupParent("noff");
    const empty = await request(app)
      .get("/api/announcements?followedOnly=true")
      .set("Authorization", `Bearer ${emptyToken}`);
    expect(empty.body.data).toEqual([]);

    // Anonymous: filter is ignored, so they still see both posts.
    const anon = await request(app).get("/api/announcements?followedOnly=true");
    expect(anon.body.data.length).toBeGreaterThanOrEqual(2);
  });
});
