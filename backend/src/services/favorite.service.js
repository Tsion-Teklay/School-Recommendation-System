import { db } from "../config/db.js";
import { NotFoundError } from "../utils/errors.js";

// ✅ Add favorite
export async function addFavorite(userId, schoolId) {
  // Check parent exists, create if not (lazy creation)
  let parent = await db.parent.findUnique({
    where: { userId },
  });

  if (!parent) {
    parent = await db.parent.create({
      data: {
        userId,
        address: "Default Address",
        latitude: 0,
        longitude: 0,
      },
    });
  }

  // Check school exists
  const school = await db.school.findUnique({
    where: { id: Number(schoolId) },
  });

  if (!school) throw new NotFoundError("School not found");

  // Create favorite (unique constraint prevents duplicates)
  const favorite = await db.favorite.create({
    data: {
      parentId: userId,
      schoolId: Number(schoolId),
    },
  });

  return favorite;
}

// ✅ Get my favorites
export async function getMyFavorites(userId) {
  const favorites = await db.favorite.findMany({
    where: { parentId: userId },
    include: {
      school: true, // return school details
    },
  });

  return favorites;
}

// ✅ Remove favorite
export async function removeFavorite(userId, schoolId) {
  const favorite = await db.favorite.findUnique({
    where: {
      parentId_schoolId: {
        parentId: userId,
        schoolId: Number(schoolId),
      },
    },
  });

  if (!favorite) throw new NotFoundError("Favorite not found");

  await db.favorite.delete({
    where: { id: favorite.id },
  });

  return { message: "Removed from favorites" };
}
