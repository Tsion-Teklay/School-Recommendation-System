import { db } from "../config/db.js";
import { NotFoundError } from "../utils/errors.js";

export async function upsertPreference(userId, data) {
  // Check if parent profile exists
  const parent = await db.parent.findUnique({
    where: { userId },
  });

  if (!parent) {
    throw new NotFoundError("Parent profile not found");
  }

  // Upsert preference
  const preference = await db.preference.upsert({
    where: { parentId: userId },
    update: {
      minBudget: data.minBudget,
      maxBudget: data.maxBudget,
      curriculum: data.curriculum,
      distance: data.distance,
    },
    create: {
      parentId: userId,
      minBudget: data.minBudget,
      maxBudget: data.maxBudget,
      curriculum: data.curriculum,
      distance: data.distance,
    },
  });

  return preference;
}

export async function getMyPreference(userId) {
  const preference = await db.preference.findUnique({
    where: { parentId: userId },
  });

  if (!preference) {
    throw new NotFoundError("Preference not found");
  }

  return preference;
}
