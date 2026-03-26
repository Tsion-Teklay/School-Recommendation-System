import { db } from "../config/db.js";
import { createNotification } from "./notification.service.js"; // 1. Import the service

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
    console.error("Notification Error:", error.message);
    // We don't throw the error here because the announcement WAS created successfully.
    // We don't want to fail the whole request just because a notification failed.
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

  if (!announcement) throw new Error("Announcement not found");

  return announcement;
}

// ✅ Update
export async function updateAnnouncement(id, data, userId) {
  const announcement = await db.announcement.findUnique({
    where: { id: Number(id) },
  });

  if (!announcement) throw new Error("Announcement not found");

  if (announcement.publisherId !== userId) {
    throw new Error("Not authorized");
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

  if (!announcement) throw new Error("Announcement not found");

  if (announcement.publisherId !== userId) {
    throw new Error("Not authorized");
  }

  await db.announcement.delete({
    where: { id: Number(id) },
  });

  return { message: "Announcement deleted successfully" };
}