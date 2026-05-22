import { db } from "../config/db.js";
import { ForbiddenError, NotFoundError } from "../utils/errors.js";
import { validateContent } from "./moderation.service.js";
import { moderateText } from "./moderation.service.js";

/**
 * Phase 5 — discussion forum.
 *
 * Two-level model: top-level posts (`threadId == null`) + replies that
 * point at a top-level post via `threadId`. We deliberately don't allow
 * deeper nesting — flat threads are simpler to render and the spec doesn't
 * call for arbitrary depth.
 *
 * Ownership: post authors can edit/delete their own posts. MODERATORs can
 * delete any post (the WARN_USER / BAN_USER side of the moderator action
 * pipeline handles the social side; deletion is the content side).
 *
 * Moderation: every body of text passes through `validateContent` before
 * insert. Edits also revalidate, so a sneaky update can't bypass the
 * blocklist by inserting a clean post first.
 */

const AUTHOR_SELECT = { id: true, fullName: true, role: true };

export async function createPost(data, userId) {
  const {
    content,
    threadId,
    targetType = "FORUM_POST",
    targetId = null,
  } = data;

  validateContent(content, { field: "content" });

  // NEW: AI moderation
  const aiModeration = await moderateText(content);
  let moderationStatus = "approved";
  if (aiModeration.toxicity >= 0.6 && aiModeration.toxicity < 0.8) {
    moderationStatus = "flagged";
  } else if (aiModeration.toxicity >= 0.8) {
    moderationStatus = "rejected";
  }

  return db.discussionForum.create({
    data: {
      authorId: userId,
      content,
      threadId: threadId ? Number(threadId) : null,
      targetType,
      targetId: targetId ? Number(targetId) : null,
      moderationStatus,
      toxicityScore: aiModeration.toxicity,
    },
    include: {
      author: { select: { id: true, fullName: true, email: true } },
      thread: true,
    },
  });
}

export async function getAnnouncementComments(announcementId) {
  return db.discussionForum.findMany({
    where: {
      targetType: "ANNOUNCEMENT",
      targetId: Number(announcementId),
      threadId: null, // Only top-level comments
    },
    include: {
      author: { select: { id: true, fullName: true, role: true } },
      replies: {
        include: {
          author: { select: { id: true, fullName: true, role: true } },
        },
        orderBy: { timestamp: "asc" },
      },
    },
    orderBy: { timestamp: "desc" },
  });
}

/**
 * Create a top-level comment on an announcement. Uses the same
 * DiscussionForum table but with targetType = ANNOUNCEMENT and
 * targetId = the announcement PK.
 */
export async function createAnnouncementComment(
  announcementId,
  content,
  userId,
) {
  validateContent(content, { field: "content" });

  // NEW: AI moderation
  const aiModeration = await moderateText(content);
  let moderationStatus = "approved";
  if (aiModeration.toxicity >= 0.6 && aiModeration.toxicity < 0.8) {
    moderationStatus = "flagged";
  } else if (aiModeration.toxicity >= 0.8) {
    moderationStatus = "rejected";
  }

  return db.discussionForum.create({
    data: {
      authorId: userId,
      content,
      targetType: "ANNOUNCEMENT",
      targetId: Number(announcementId),
      moderationStatus,
      toxicityScore: aiModeration.toxicity,
    },
    include: {
      author: { select: { id: true, fullName: true, role: true } },
    },
  });
}

export async function replyToPost(authorId, parentId, { content }) {
  validateContent(content, { field: "content" });

  // NEW: AI moderation
  const aiModeration = await moderateText(content);
  let moderationStatus = "approved";
  if (aiModeration.toxicity >= 0.6 && aiModeration.toxicity < 0.8) {
    moderationStatus = "flagged";
  } else if (aiModeration.toxicity >= 0.8) {
    moderationStatus = "rejected";
  }

  const parent = await db.discussionForum.findUnique({
    where: { id: Number(parentId) },
    select: { id: true, threadId: true },
  });
  if (!parent) throw new NotFoundError("Forum post not found");
  const threadId = parent.threadId ?? parent.id;

  return db.discussionForum.create({
    data: {
      authorId,
      content,
      threadId,
      moderationStatus,
      toxicityScore: aiModeration.toxicity,
    },
    include: { author: { select: AUTHOR_SELECT } },
  });
}

export async function listTopLevelPosts({ page = 1, limit = 10 } = {}) {
  const skip = (Number(page) - 1) * Number(limit);
  const where = { threadId: null, targetType: "FORUM_POST" };
  const [posts, total] = await Promise.all([
    db.discussionForum.findMany({
      where,
      skip,
      take: Number(limit),
      orderBy: { timestamp: "desc" },
      include: {
        author: { select: AUTHOR_SELECT },
        _count: { select: { replies: true } },
      },
    }),
    db.discussionForum.count({ where }),
  ]);
  return {
    data: posts.map((p) => ({
      ...p,
      replyCount: p._count.replies,
      _count: undefined,
    })),
    meta: {
      total,
      page: Number(page),
      totalPages: Math.ceil(total / Number(limit)),
    },
  };
}

export async function getPostWithReplies(postId) {
  const id = Number(postId);
  const post = await db.discussionForum.findUnique({
    where: { id },
    include: {
      author: { select: AUTHOR_SELECT },
      replies: {
        orderBy: { timestamp: "asc" },
        include: { author: { select: AUTHOR_SELECT } },
      },
    },
  });
  if (!post) throw new NotFoundError("Forum post not found");
  return post;
}

export async function updatePost(authorId, postId, { content }) {
  validateContent(content, { field: "content" });

  // NEW: AI moderation
  const aiModeration = await moderateText(content);
  let moderationStatus = "approved";
  if (aiModeration.toxicity >= 0.6 && aiModeration.toxicity < 0.8) {
    moderationStatus = "flagged";
  } else if (aiModeration.toxicity >= 0.8) {
    moderationStatus = "rejected";
  }

  const post = await db.discussionForum.findUnique({
    where: { id: Number(postId) },
    select: { id: true, authorId: true },
  });
  if (!post) throw new NotFoundError("Forum post not found");
  if (post.authorId !== authorId) {
    throw new ForbiddenError("Not authorized to edit this post");
  }
  return db.discussionForum.update({
    where: { id: post.id },
    data: {
      content,
      isEdited: true,
      moderationStatus,
      toxicityScore: aiModeration.toxicity,
    },
    include: { author: { select: AUTHOR_SELECT } },
  });
}

/**
 * Delete a post. Authors can delete their own; MODERATORs can delete any.
 * Replies under the post are deleted first so the FK constraint holds.
 */
export async function deletePost(user, postId) {
  const id = Number(postId);
  const post = await db.discussionForum.findUnique({
    where: { id },
    select: { id: true, authorId: true, threadId: true },
  });
  if (!post) throw new NotFoundError("Forum post not found");

  const isAuthor = post.authorId === user.id;
  const isModerator = user.role === "MODERATOR";
  if (!isAuthor && !isModerator) {
    throw new ForbiddenError("Not authorized to delete this post");
  }

  if (post.threadId == null) {
    // Top-level: cascade delete its replies first.
    await db.$transaction([
      db.discussionForum.deleteMany({ where: { threadId: id } }),
      db.discussionForum.delete({ where: { id } }),
    ]);
  } else {
    await db.discussionForum.delete({ where: { id } });
  }

  return { message: "Forum post deleted" };
}

/**
 * Used by moderation.takeAction(REMOVE_CONTENT) when the report target is a
 * forum post. Bypasses the author-or-moderator check (caller already
 * authorized via the moderator role).
 */
export async function deletePostAsModerator(postId) {
  const id = Number(postId);
  const post = await db.discussionForum.findUnique({
    where: { id },
    select: { id: true, threadId: true, authorId: true },
  });
  if (!post) return { authorId: null };

  if (post.threadId == null) {
    await db.$transaction([
      db.discussionForum.deleteMany({ where: { threadId: id } }),
      db.discussionForum.delete({ where: { id } }),
    ]);
  } else {
    await db.discussionForum.delete({ where: { id } });
  }
  return { authorId: post.authorId };
}
