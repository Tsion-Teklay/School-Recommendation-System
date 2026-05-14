import { db } from "../config/db.js";
import { NotFoundError, ConflictError } from "../utils/errors.js";

export async function toggleLike(userId, targetType, targetId) {
  const existing = await db.like.findUnique({
    where: {
      userId_targetType_targetId: {
        userId,
        targetType,
        targetId: Number(targetId),
      },
    },
  });

  if (existing) {
    await db.like.delete({ where: { id: existing.id } });
    return { liked: false };
  }

  await db.like.create({
    data: {
      userId,
      targetType,
      targetId: Number(targetId),
    },
  });

  return { liked: true };
}

export async function getLikeCount(targetType, targetId) {
  return db.like.count({
    where: {
      targetType,
      targetId: Number(targetId),
    },
  });
}

export async function getUserLikeStatus(userId, targetType, targetId) {
  const like = await db.like.findUnique({
    where: {
      userId_targetType_targetId: {
        userId,
        targetType,
        targetId: Number(targetId),
      },
    },
  });
  return { liked: !!like };
}
