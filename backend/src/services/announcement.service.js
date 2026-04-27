import { db } from "../config/db.js";
import {
  ForbiddenError,
  NotFoundError,
  ValidationError,
} from "../utils/errors.js";
import { logger } from "../config/logger.js";
import { createNotification } from "./notification.service.js";

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
export async function getAllAnnouncements(query) {
  const { category, urgencyLevel, page = 1, limit = 10 } = query;

  const where = {
    ...(category && { category }),
    ...(urgencyLevel && { urgencyLevel }),
  };

  const skip = (Number(page) - 1) * Number(limit);

  const [announcements, total] = await Promise.all([
    db.announcement.findMany({
      where,
      skip,
      take: Number(limit),
      orderBy: { createdAt: "desc" },
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
  });

  if (!announcement) throw new NotFoundError("Announcement not found");

  return announcement;
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
