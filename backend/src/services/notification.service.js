import { db } from "../config/db.js";

// ✅ Create Notification (internal use)
export async function createNotification({
  recipientId,
  recipientType,
  message,
  sourceType,
  sourceId, // 1. Add this
}) {
  return db.notification.create({
    data: {
      recipientId,
      recipientType,
      message,
      sourceType,
      sourceId: Number(sourceId), // 2. Add this (ensure it's a number)
    },
  });
}

// ✅ Get My Notifications
export async function getMyNotifications(userId, query) {
  const { page = 1, limit = 10, unread } = query;

  const where = {
    recipientId: userId,
    ...(unread === "true" && { isRead: false }),
  };

  const skip = (Number(page) - 1) * Number(limit); // Ensure these are numbers

  const [notifications, total] = await Promise.all([
    db.notification.findMany({
      where,
      skip: Number(skip),
      take: Number(limit),
      orderBy: { createdAt: "desc" },
    }),
    db.notification.count({ where }),
  ]);

  return {
    data: notifications,
    meta: {
      total,
      page: Number(page),
      totalPages: Math.ceil(total / Number(limit)),
    },
  };
}

// ✅ Mark as Read
export async function markAsRead(id, userId) {
  const notification = await db.notification.findUnique({
    where: { id: Number(id) },
  });

  if (!notification) throw new Error("Notification not found");

  if (notification.recipientId !== userId) {
    throw new Error("Not authorized");
  }

  return db.notification.update({
    where: { id: Number(id) },
    data: { isRead: true },
  });
}