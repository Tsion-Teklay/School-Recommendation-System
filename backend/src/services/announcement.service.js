import { db } from "../config/db.js";
import { ForbiddenError, NotFoundError } from "../utils/errors.js";
import { logger } from "../config/logger.js";
import { createNotification } from "./notification.service.js";

// ✅ Create
export async function createAnnouncement(data, user) {
  const publisherType =
    user.role === "MOE_OFFICER" ? "MOE" : "SCHOOL_ADMIN";

  const announcement = await db.announcement.create({
    data: {
      ...data,
      publisherId: user.id,
      publisherType,
    },
  });

  // 🚀 INTEGRATION: Notify all Parents
  try {
    const parents = await db.user.findMany({
      where: { role: "PARENT" },
      select: { id: true } // Only fetch IDs to keep it fast
    });

    // Fire and forget notifications in parallel
    await Promise.all(
      parents.map((p) =>
        createNotification({
          recipientId: p.id,
          recipientType: "PARENT",
          message: `New announcement: ${announcement.title}`,
          sourceId: announcement.id, // Passes as Number
          sourceType: "ANNOUNCEMENT",
        })
      )
    );
  } catch (error) {
    logger.warn({ err: error }, "Announcement notification fan-out failed");
    // Announcement creation succeeded — don't fail the request if notifications did.
    // NOTE: Phase 4 will replace this blast-all with a Subscription/Follow-driven fan-out.
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
