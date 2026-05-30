import { db } from "../config/db.js";
import {
  ForbiddenError,
  NotFoundError,
  ValidationError,
} from "../utils/errors.js";

/**
 * Facility image management.
 *
 * Pictures live on disk under `uploads/facility-images/` (see `uploads.js`).
 * This service only stores/removes the row in `FacilityImage`; the multer
 * middleware has already moved the file before we're called.
 *
 * Ownership rule mirrors the school routes themselves: only the SCHOOL_ADMIN
 * who owns the school (i.e. `school.adminId === user.id`) can add or remove
 * its images. The roles middleware enforces SCHOOL_ADMIN; we add the
 * ownership check here so users can't write across schools.
 */
async function loadOwnedSchool(schoolId, userId) {
  const school = await db.school.findUnique({
    where: { id: Number(schoolId) },
    select: { id: true, adminId: true },
  });
  if (!school) throw new NotFoundError("School not found");
  if (school.adminId !== userId) {
    throw new ForbiddenError(
      "You can only manage images for your own school"
    );
  }
  return school;
}

export async function addFacilityImage({ schoolId, imageUrl, userId }) {
  if (!imageUrl) throw new ValidationError("imageUrl is required");
  await loadOwnedSchool(schoolId, userId);
  const created = await db.facilityImage.create({
    data: { schoolId: Number(schoolId), imageUrl },
    select: { id: true, schoolId: true, imageUrl: true },
  });
  return created;
}

export async function deleteFacilityImage({ schoolId, imageId, userId }) {
  await loadOwnedSchool(schoolId, userId);
  const image = await db.facilityImage.findUnique({
    where: { id: Number(imageId) },
    select: { id: true, schoolId: true },
  });
  if (!image) throw new NotFoundError("Image not found");
  // Defensive: don't let an admin delete an image that belongs to a
  // different school even if the row id is theirs by mistake. The path
  // already encodes the schoolId so this only fires on a client bug.
  if (image.schoolId !== Number(schoolId)) {
    throw new NotFoundError("Image not found on this school");
  }
  await db.facilityImage.delete({ where: { id: image.id } });
  return { id: image.id };
}

export async function listFacilityImages(schoolId) {
  return db.facilityImage.findMany({
    where: { schoolId: Number(schoolId) },
    select: { id: true, imageUrl: true },
    orderBy: { id: "asc" },
  });
}
