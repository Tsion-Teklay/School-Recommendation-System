import { db } from "../config/db.js";

// ✅ Add favorite
export async function addFavorite(userId, schoolId) {
  // Check parent exists
  const parent = await db.parent.findUnique({
    where: { userId },
  });

  if (!parent) throw new Error("Parent profile not found");

  // Check school exists
  const school = await db.school.findUnique({
    where: { id: Number(schoolId) },
  });

  if (!school) throw new Error("School not found");

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

  if (!favorite) throw new Error("Favorite not found");

  await db.favorite.delete({
    where: { id: favorite.id },
  });

  return { message: "Removed from favorites" };
}