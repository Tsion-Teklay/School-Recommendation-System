import { db } from "../config/db.js";

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