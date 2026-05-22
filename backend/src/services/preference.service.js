import { db } from "../config/db.js";
import { NotFoundError, ValidationError } from "../utils/errors.js";


export async function upsertPreference(userId, data) {
  const parent = await db.parent.findUnique({ where: { userId } });

  const hasLocation =
    data.address != null && data.latitude != null && data.longitude != null;

  
  if (!parent) {
    if (!hasLocation) {
      throw new ValidationError(
        "First-time setup requires address, latitude, and longitude"
      );
    }
    await db.parent.create({
      data: {
        userId,
        address: data.address,
        latitude: data.latitude,
        longitude: data.longitude,
      },
    });
  } else if (data.address != null || data.latitude != null || data.longitude != null) {
    // Branch 2: existing parent updating their home pin. Schema guarantees
    // lat/lng are paired; only update fields the client actually sent.
    await db.parent.update({
      where: { userId },
      data: {
        ...(data.address != null && { address: data.address }),
        ...(data.latitude != null && { latitude: data.latitude }),
        ...(data.longitude != null && { longitude: data.longitude }),
      },
    });
  }

  const preference = await db.preference.upsert({
    where: { parentId: userId },
    update: {
      minBudget: data.minBudget,
      maxBudget: data.maxBudget,
      curriculum: data.curriculum,
      distance: data.distance,
      schoolLevel: data.schoolLevel,     
    schoolType: data.schoolType,        
    },
    create: {
      parentId: userId,
      minBudget: data.minBudget,
      maxBudget: data.maxBudget,
      curriculum: data.curriculum,
      distance: data.distance,
      schoolLevel: data.schoolLevel,    
    schoolType: data.schoolType,        
    },
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
    address: parent?.address ?? null,
    latitude: parent?.latitude ?? null,
    longitude: parent?.longitude ?? null,
  };
}
