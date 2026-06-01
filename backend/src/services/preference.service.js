import { db } from "../config/db.js";
import { NotFoundError, ValidationError } from "../utils/errors.js";


export async function upsertPreference(userId, data) {
  const parentUpdateData = {};
  const parentCreateData = { userId };

  if (data.latitude != null) {
    parentUpdateData.latitude = data.latitude;
    parentCreateData.latitude = data.latitude;
  }
  if (data.longitude != null) {
    parentUpdateData.longitude = data.longitude;
    parentCreateData.longitude = data.longitude;
  }

  const parent = await db.parent.upsert({
    where: { userId },
    update: parentUpdateData,
    create: parentCreateData,
  });

  // Build preference data, only including fields that are not null/undefined
  const preferenceUpdateData = {};
  const preferenceCreateData = { parentId: userId };

  if (data.minBudget != null) {
    preferenceUpdateData.minBudget = data.minBudget;
    preferenceCreateData.minBudget = data.minBudget;
  }
  if (data.maxBudget != null) {
    preferenceUpdateData.maxBudget = data.maxBudget;
    preferenceCreateData.maxBudget = data.maxBudget;
  }
  if (data.curriculum != null) {
    preferenceUpdateData.curriculum = data.curriculum;
    preferenceCreateData.curriculum = data.curriculum;
  }
  if (data.distance != null) {
    preferenceUpdateData.distance = data.distance;
    preferenceCreateData.distance = data.distance;
  }
  if (data.schoolLevel != null) {
    preferenceUpdateData.schoolLevel = data.schoolLevel;
    preferenceCreateData.schoolLevel = data.schoolLevel;
  }
  if (data.schoolType != null) {
    preferenceUpdateData.schoolType = data.schoolType;
    preferenceCreateData.schoolType = data.schoolType;
  }

  const preference = await db.preference.upsert({
    where: { parentId: userId },
    update: preferenceUpdateData,
    create: preferenceCreateData,
  });

  return preference;
}


export async function getMyPreference(userId) {
  const [preference, parent] = await Promise.all([
    db.preference.findUnique({ where: { parentId: userId } }),
    db.parent.findUnique({ where: { userId } }),
  ]);

  return {
    minBudget: preference?.minBudget ?? null,
    maxBudget: preference?.maxBudget ?? null,
    curriculum: preference?.curriculum ?? null,
    distance: preference?.distance ?? null,
    schoolLevel: preference?.schoolLevel ?? null, 
  schoolType: preference?.schoolType ?? null,     
    latitude: parent?.latitude ?? null,
    longitude: parent?.longitude ?? null,
  };
}
