import { db } from "../config/db.js";
import { NotFoundError } from "../utils/errors.js";

export async function addFavorite(userId, schoolId) {
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

  const school = await db.school.findUnique({
    where: { id: Number(schoolId) },
  });

  if (!school) throw new NotFoundError("School not found");

  const favorite = await db.favorite.create({
    data: {
      parentId: userId,
      schoolId: Number(schoolId),
    },
  });

  return favorite;
}

export async function getMyFavorites(userId) {
  const favorites = await db.favorite.findMany({
    where: { parentId: userId },
    include: {
      school: true,
    },
  });

  return favorites;
}

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
