import { db } from "../config/db.js";
import {
  ForbiddenError,
  NotFoundError,
  ValidationError,
} from "../utils/errors.js";
import { logger } from "../config/logger.js";
import { createNotification } from "./notification.service.js";
import { validateContent } from "./moderation.service.js";

/**
 * Phase 4 — targeted announcement fan-out.
 *
 * Two publisher paths now diverge:
 *
 *   SCHOOL_ADMIN: announcement is school-scoped (announcement.schoolId set,
 *     ownership of the school enforced) and only parents subscribed to that
 *     school via the Subscription table receive a notification. This is the
 *     UC09 / UC18 / UC21 behaviour the spec calls for — replacing the prior
 *     blast-all that violated those use cases.
 *
 *   MOE_OFFICER: announcement is platform-wide (no schoolId) and every
 *     parent gets a notification, same as before.
 *
 * Both paths swallow notification failures — announcement creation is the
 * primary write and shouldn't 5xx because a downstream insert blew up.
 */
export async function createAnnouncement(data, user) {
  const publisherType = user.role === "MOE_OFFICER" ? "MOE" : "SCHOOL_ADMIN";

  let { schoolId, ...rest } = data;
  schoolId = schoolId === undefined || schoolId === null ? null : Number(schoolId);

  if (publisherType === "SCHOOL_ADMIN") {
    if (!schoolId) {
      throw new ValidationError(
        "schoolId is required for SCHOOL_ADMIN announcements"
      );
    }
    const school = await db.school.findUnique({
      where: { id: schoolId },
      select: { id: true, adminId: true },
    });
    if (!school) throw new NotFoundError("School not found");
    if (school.adminId !== user.id) {
      throw new ForbiddenError("You can only post announcements for your own school");
    }
  } else {
    // MoE-level posts are platform-wide; ignore any client-supplied schoolId.
    schoolId = null;
  }

  // Phase 5 — content moderation. Title + body both pass through the
  // validator. Throws CONTENT_REJECTED before we hit the DB.
  validateContent(rest.title, { field: "title" });
  validateContent(rest.content, { field: "content" });

  const announcement = await db.announcement.create({
    data: {
      ...rest,
      schoolId,
      publisherId: user.id,
      publisherType,
    },
  });

  // 🚀 Targeted fan-out
  try {
    let recipientIds;
    if (publisherType === "MOE") {
      const parents = await db.user.findMany({
        where: { role: "PARENT" },
        select: { id: true },
      });
      recipientIds = parents.map((p) => p.id);
    } else {
      const subs = await db.subscription.findMany({
        where: { schoolId },
        select: { parentId: true },
      });
      recipientIds = subs.map((s) => s.parentId);
    }

    await Promise.all(
      recipientIds.map((id) =>
        createNotification({
          recipientId: id,
          recipientType: "PARENT",
          message: `New announcement: ${announcement.title}`,
          sourceId: announcement.id,
          sourceType: "ANNOUNCEMENT",
        })
      )
    );
  } catch (error) {
    logger.warn({ err: error }, "Announcement notification fan-out failed");
    // Announcement creation succeeded — don't fail the request if notifications did.
  }

  return announcement;
}


// ✅ Get All (with filters + pagination)
export async function getAllAnnouncements(query, user) {
  const {
    category,
    urgencyLevel,
    schoolId,
    followedOnly,
    page = 1,
    limit = 10,
  } = query;

  const where = {
    ...(category && { category }),
    ...(urgencyLevel && { urgencyLevel }),
    ...(schoolId && { schoolId: Number(schoolId) }),
  };

  // Phase 11 — "only schools I follow". Requires an authenticated parent; we
  // silently drop the filter for everyone else so the route stays public.
  if (followedOnly && user && user.role === "PARENT") {
    const subs = await db.subscription.findMany({
      where: { parentId: user.id },
      select: { schoolId: true },
    });
    const ids = subs.map((s) => s.schoolId);
    // If the parent follows nothing, return an empty page rather than the
    // full feed — that matches user intent.
    if (ids.length === 0) {
      return {
        data: [],
        meta: { total: 0, page: Number(page), totalPages: 0 },
      };
    }
    where.schoolId = { in: ids };
  }

  const skip = (Number(page) - 1) * Number(limit);

  const [announcements, total] = await Promise.all([
    db.announcement.findMany({
      where,
      skip,
      take: Number(limit),
      orderBy: { createdAt: "desc" },
      include: {
        // Phase 11 — feed cards need the school name + verification badge
        // without a roundtrip per announcement.
        school: {
          select: {
            id: true,
            schoolName: true,
            verificationStatus: true,
          },
        },
      },
    }),
    db.announcement.count({ where }),
  ]);

  return {
    data: announcements,
    meta: {
      total,
      page: Number(page),
      totalPages: Math.ceil(total / limit),
    },
  };
}

// ✅ Get One
export async function getAnnouncementById(id) {
  const announcement = await db.announcement.findUnique({
    where: { id: Number(id) },
    include: {
      school: {
        select: { id: true, schoolName: true, verificationStatus: true },
      },
    },
  });

  if (!announcement) throw new NotFoundError("Announcement not found");

  return announcement;
}

// Phase 11 — image upload pipeline for school announcements. The multer
// middleware writes the file to disk; this function only flips the row's
// `imgUrl` column. SCHOOL_ADMIN owns the announcement they created (and
// implicitly the school the announcement belongs to). MoE-level posts can
// also have an image attached by the MoE officer who created them.
export async function setAnnouncementImage({ id, imageUrl, userId }) {
  const announcement = await db.announcement.findUnique({
    where: { id: Number(id) },
    select: { id: true, publisherId: true },
  });
  if (!announcement) throw new NotFoundError("Announcement not found");
  if (announcement.publisherId !== userId) {
    throw new ForbiddenError(
      "You can only attach images to your own announcements"
    );
  }
  return db.announcement.update({
    where: { id: announcement.id },
    data: { imgUrl: imageUrl },
  });
}

export async function clearAnnouncementImage({ id, userId }) {
  const announcement = await db.announcement.findUnique({
    where: { id: Number(id) },
    select: { id: true, publisherId: true },
  });
  if (!announcement) throw new NotFoundError("Announcement not found");
  if (announcement.publisherId !== userId) {
    throw new ForbiddenError(
      "You can only clear images on your own announcements"
    );
  }
  return db.announcement.update({
    where: { id: announcement.id },
    data: { imgUrl: null },
  });
}

// ✅ Update
export async function updateAnnouncement(id, data, userId) {
  const announcement = await db.announcement.findUnique({
    where: { id: Number(id) },
  });

  if (!announcement) throw new NotFoundError("Announcement not found");

  if (announcement.publisherId !== userId) {
    throw new ForbiddenError("Not authorized to update this announcement");
  }

  if (data.title) validateContent(data.title, { field: "title" });
  if (data.content) validateContent(data.content, { field: "content" });

  return db.announcement.update({
    where: { id: Number(id) },
    data,
  });
}

// ✅ Delete
export async function deleteAnnouncement(id, userId) {
  const announcement = await db.announcement.findUnique({
    where: { id: Number(id) },
  });

  if (!announcement) throw new NotFoundError("Announcement not found");

  if (announcement.publisherId !== userId) {
    throw new ForbiddenError("Not authorized to delete this announcement");
  }

  await db.announcement.delete({
    where: { id: Number(id) },
  });

  return { message: "Announcement deleted successfully" };
}
