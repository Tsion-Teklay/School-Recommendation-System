/**
 * Phase 5 — forum + content moderation + typed moderator actions.
 *
 * Covers:
 *   - Forum CRUD (top-level posts + replies, ownership, MODERATOR delete).
 *   - Content moderation rejecting reviews / forum posts / announcements.
 *   - Typed moderator actions (DISMISS, REMOVE_CONTENT, WARN_USER, BAN_USER)
 *     with their concrete side effects.
 */
import request from "supertest";
import app from "../app.js";
import { db } from "../config/db.js";
import { cleanDatabase } from "./utils/cleanup.js";
import { registerVerifiedUser } from "./utils/auth.js";

let parentAToken;
let parentAId;
let parentBToken;
let parentBId;
let modToken;
let adminToken;
let adminId;
let schoolId;

beforeAll(async () => {
  await cleanDatabase();

  ({ token: parentAToken, user: { id: parentAId } } = await registerVerifiedUser({
    fullName: "Parent A",
    email: "p5-parentA@test.com",
    phone: "+251911222001",
    role: "PARENT",
  }));
  // Parents need a Parent profile to write reviews (see review.service).
  await db.parent.create({
    data: { userId: parentAId, latitude: 9, longitude: 38 },
  });

  ({ token: parentBToken, user: { id: parentBId } } = await registerVerifiedUser({
    fullName: "Parent B",
    email: "p5-parentB@test.com",
    phone: "+251911222002",
    role: "PARENT",
  }));
  await db.parent.create({
    data: { userId: parentBId, latitude: 9, longitude: 38 },
  });

  ({ token: modToken } = await registerVerifiedUser({
    fullName: "Mod",
    email: "p5-mod@test.com",
    phone: "+251911222003",
    role: "MODERATOR",
  }));

  ({ token: adminToken, user: { id: adminId } } = await registerVerifiedUser({
    fullName: "Admin",
    email: "p5-admin@test.com",
    phone: "+251911222004",
    role: "SCHOOL_ADMIN",
  }));

  // One school for review / announcement tests below.
  const school = await db.school.create({
    data: {
      adminId,
      schoolName: "P5 School",
      address: "addr",
      contactEmail: "s@p5.test",
      contactPhone: "+251911000000",
      curriculum: "LOCAL",
      tuitionFee: "1000.00",
      latitude: 9,
      longitude: 38,
    },
  });
  schoolId = school.id;
});

afterAll(async () => {
  await db.$disconnect();
});

// -------------------------------------------------------------------------
// Forum CRUD
// -------------------------------------------------------------------------
describe("Phase 5 — Forum", () => {
  let topPostId;
  let replyId;

  it("rejects unauthenticated post creation", async () => {
    const res = await request(app)
      .post("/api/forum")
      .send({ content: "hi" });
    expect(res.statusCode).toBe(401);
  });

  it("creates a top-level post", async () => {
    const res = await request(app)
      .post("/api/forum")
      .set("Authorization", `Bearer ${parentAToken}`)
      .send({ content: "Anyone got tips for choosing a school?" });
    expect(res.statusCode).toBe(201);
    expect(res.body.post.threadId).toBeNull();
    expect(res.body.post.author.id).toBe(parentAId);
    topPostId = res.body.post.id;
  });

  it("rejects empty content (Zod)", async () => {
    const res = await request(app)
      .post("/api/forum")
      .set("Authorization", `Bearer ${parentAToken}`)
      .send({ content: "" });
    expect(res.statusCode).toBe(400);
    expect(res.body.code).toBe("VALIDATION_ERROR");
  });

  it("rejects content with blocklisted words", async () => {
    const res = await request(app)
      .post("/api/forum")
      .set("Authorization", `Bearer ${parentAToken}`)
      .send({ content: "this is total spam" });
    expect(res.statusCode).toBe(400);
    expect(res.body.code).toBe("CONTENT_REJECTED");
  });

  it("lists top-level posts (anonymous, paginated)", async () => {
    const res = await request(app).get("/api/forum?page=1&limit=10");
    expect(res.statusCode).toBe(200);
    expect(res.body.data.length).toBeGreaterThanOrEqual(1);
    expect(res.body.meta).toHaveProperty("total");
  });

  it("creates a reply", async () => {
    const res = await request(app)
      .post(`/api/forum/${topPostId}/replies`)
      .set("Authorization", `Bearer ${parentBToken}`)
      .send({ content: "Try checking the curriculum first." });
    expect(res.statusCode).toBe(201);
    expect(res.body.post.threadId).toBe(topPostId);
    replyId = res.body.post.id;
  });

  it("flattens replies-to-replies onto the original thread", async () => {
    const res = await request(app)
      .post(`/api/forum/${replyId}/replies`)
      .set("Authorization", `Bearer ${parentAToken}`)
      .send({ content: "Thanks!" });
    expect(res.statusCode).toBe(201);
    // threadId points at top-level post, NOT the reply we replied to
    expect(res.body.post.threadId).toBe(topPostId);
  });

  it("returns post with replies", async () => {
    const res = await request(app).get(`/api/forum/${topPostId}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.post.id).toBe(topPostId);
    expect(Array.isArray(res.body.post.replies)).toBe(true);
    expect(res.body.post.replies.length).toBeGreaterThanOrEqual(2);
  });

  it("rejects edit by non-author (403)", async () => {
    const res = await request(app)
      .put(`/api/forum/${topPostId}`)
      .set("Authorization", `Bearer ${parentBToken}`)
      .send({ content: "edited by stranger" });
    expect(res.statusCode).toBe(403);
  });

  it("allows author to edit + sets isEdited", async () => {
    const res = await request(app)
      .put(`/api/forum/${topPostId}`)
      .set("Authorization", `Bearer ${parentAToken}`)
      .send({ content: "edited content" });
    expect(res.statusCode).toBe(200);
    expect(res.body.post.isEdited).toBe(true);
    expect(res.body.post.content).toBe("edited content");
  });

  it("rejects delete by non-author non-moderator (403)", async () => {
    const res = await request(app)
      .delete(`/api/forum/${replyId}`)
      .set("Authorization", `Bearer ${parentAToken}`);
    // parentA didn't author this reply (parentB did)
    expect(res.statusCode).toBe(403);
  });

  it("allows MODERATOR to delete any post", async () => {
    const res = await request(app)
      .delete(`/api/forum/${replyId}`)
      .set("Authorization", `Bearer ${modToken}`);
    expect(res.statusCode).toBe(200);
  });
});

// -------------------------------------------------------------------------
// Content moderation
// -------------------------------------------------------------------------
describe("Phase 5 — Content moderation wiring", () => {
  it("rejects review with profanity in comment", async () => {
    const res = await request(app)
      .post(`/api/reviews/${schoolId}`)
      .set("Authorization", `Bearer ${parentAToken}`)
      .send({
        rating: 4,
        comment: "this teacher is an idiot",
        categoryTag: "TEACHING_QUALITY",
      });
    expect(res.statusCode).toBe(400);
    expect(res.body.code).toBe("CONTENT_REJECTED");
  });

  it("rejects announcement with profanity in body", async () => {
    const res = await request(app)
      .post("/api/announcements/school")
      .set("Authorization", `Bearer ${adminToken}`)
      .send({
        title: "Fee update",
        content: "the new policy is stupid and bad",
        category: "FEE",
        urgencyLevel: "NORMAL",
        schoolId,
      });
    expect(res.statusCode).toBe(400);
    expect(res.body.code).toBe("CONTENT_REJECTED");
  });

  it("accepts clean review", async () => {
    const res = await request(app)
      .post(`/api/reviews/${schoolId}`)
      .set("Authorization", `Bearer ${parentAToken}`)
      .send({
        rating: 5,
        comment: "Excellent teaching staff and facilities.",
        categoryTag: "TEACHING_QUALITY",
      });
    expect(res.statusCode).toBe(201);
  });
});

// -------------------------------------------------------------------------
// Typed moderator actions + side effects
// -------------------------------------------------------------------------
describe("Phase 5 — Moderator actions with side effects", () => {
  let cleanReviewId;
  let cleanReportId;
  let postToRemoveId;
  let postReportId;

  beforeAll(async () => {
    // Create a review by parentB so the moderator can remove it.
    const r = await db.review.create({
      data: {
        parentId: parentBId,
        schoolId,
        rating: 1,
        comment: "Targeted for removal",
        categoryTag: "OTHER",
      },
    });
    cleanReviewId = r.id;
    await db.school.update({
      where: { id: schoolId },
      data: { reviewCount: { increment: 1 } },
    });

    // Report the review.
    const repA = await db.report.create({
      data: {
        reporterId: parentAId,
        targetType: "REVIEW",
        targetId: cleanReviewId,
        reason: "off-topic",
      },
    });
    cleanReportId = repA.id;

    // Create a forum post by parentA + report it.
    const fp = await db.discussionForum.create({
      data: { authorId: parentAId, content: "questionable post" },
    });
    postToRemoveId = fp.id;
    const repB = await db.report.create({
      data: {
        reporterId: parentBId,
        targetType: "FORUM_POST",
        targetId: postToRemoveId,
        reason: "trolling",
      },
    });
    postReportId = repB.id;
  });

  it("rejects unknown actionType (Zod enum)", async () => {
    const res = await request(app)
      .post(`/api/reports/${cleanReportId}/action`)
      .set("Authorization", `Bearer ${modToken}`)
      .send({ actionType: "NUKE" });
    expect(res.statusCode).toBe(400);
    expect(res.body.code).toBe("VALIDATION_ERROR");
  });

  it("REMOVE_CONTENT deletes the review + recomputes school rating", async () => {
    const before = await db.school.findUnique({
      where: { id: schoolId },
      select: { reviewCount: true, rating: true },
    });

    const res = await request(app)
      .post(`/api/reports/${cleanReportId}/action`)
      .set("Authorization", `Bearer ${modToken}`)
      .send({ actionType: "REMOVE_CONTENT", notes: "off-topic" });
    expect(res.statusCode).toBe(200);

    const reviewStill = await db.review.findUnique({
      where: { id: cleanReviewId },
    });
    expect(reviewStill).toBeNull();

    const after = await db.school.findUnique({
      where: { id: schoolId },
      select: { reviewCount: true, rating: true },
    });
    expect(after.reviewCount).toBe(before.reviewCount - 1);

    // Author (parentB) should have been notified
    const notif = await db.notification.findFirst({
      where: { recipientId: parentBId, sourceType: "MODERATION" },
      orderBy: { id: "desc" },
    });
    expect(notif).not.toBeNull();
    expect(notif.message).toMatch(/review was removed/i);

    // Report flipped to RESOLVED
    const rep = await db.report.findUnique({ where: { id: cleanReportId } });
    expect(rep.status).toBe("RESOLVED");
  });

  it("REMOVE_CONTENT on FORUM_POST deletes the post + notifies author", async () => {
    const res = await request(app)
      .post(`/api/reports/${postReportId}/action`)
      .set("Authorization", `Bearer ${modToken}`)
      .send({ actionType: "REMOVE_CONTENT", notes: "trolling" });
    expect(res.statusCode).toBe(200);

    const post = await db.discussionForum.findUnique({
      where: { id: postToRemoveId },
    });
    expect(post).toBeNull();
  });

  it("WARN_USER keeps the review but notifies the author", async () => {
    // Re-seed: clean review by parentB + report.
    const review = await db.review.create({
      data: {
        parentId: parentBId,
        schoolId,
        rating: 2,
        comment: "warning candidate",
        categoryTag: "OTHER",
      },
    });
    const rep = await db.report.create({
      data: {
        reporterId: parentAId,
        targetType: "REVIEW",
        targetId: review.id,
        reason: "tone",
      },
    });

    const res = await request(app)
      .post(`/api/reports/${rep.id}/action`)
      .set("Authorization", `Bearer ${modToken}`)
      .send({ actionType: "WARN_USER", notes: "be nicer" });
    expect(res.statusCode).toBe(200);

    // Review still exists.
    const stillThere = await db.review.findUnique({ where: { id: review.id } });
    expect(stillThere).not.toBeNull();

    const notif = await db.notification.findFirst({
      where: { recipientId: parentBId, sourceId: rep.id, sourceType: "MODERATION" },
    });
    expect(notif).not.toBeNull();
    expect(notif.message).toMatch(/warning/i);
  });

  it("BAN_USER deactivates the user account", async () => {
    // Use a fresh user so we don't break later tests.
    const banned = await registerVerifiedUser({
      fullName: "Banee",
      email: "p5-banee@test.com",
      phone: "+251911222+25199",
      role: "PARENT",
    });
    await db.parent.create({
      data: { userId: banned.user.id, latitude: 9, longitude: 38 },
    });
    const review = await db.review.create({
      data: {
        parentId: banned.user.id,
        schoolId,
        rating: 1,
        comment: "ban candidate",
        categoryTag: "OTHER",
      },
    });
    const rep = await db.report.create({
      data: {
        reporterId: parentAId,
        targetType: "REVIEW",
        targetId: review.id,
        reason: "harassment",
      },
    });

    const res = await request(app)
      .post(`/api/reports/${rep.id}/action`)
      .set("Authorization", `Bearer ${modToken}`)
      .send({ actionType: "BAN_USER", notes: "repeat offender" });
    expect(res.statusCode).toBe(200);

    const u = await db.user.findUnique({ where: { id: banned.user.id } });
    expect(u.accountStatus).toBe("DEACTIVATED");

    // Banned user can no longer log in (auth.service throws UnauthorizedError
    // -> 401 for deactivated accounts).
    const login = await request(app).post("/api/auth/login").send({
      email: "p5-banee@test.com",
      password: "123456",
    });
    expect(login.statusCode).toBe(401);
    expect(login.body.error).toMatch(/deactivated/i);
  });
});
