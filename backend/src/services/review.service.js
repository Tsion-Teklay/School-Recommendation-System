import { db } from "../config/db.js";
import { ConflictError, ForbiddenError, NotFoundError, ValidationError } from "../utils/errors.js";

// ✅ Create review
export async function createReview(userId, schoolId, data) {
  const parent = await db.parent.findUnique({
    where: { userId },
  });

  if (!parent) throw new NotFoundError("Parent profile not found");

  const existing = await db.review.findFirst({
    where: {
      parentId: userId,
      schoolId: Number(schoolId),
    },
  });

  if (existing) {
    throw new ConflictError("You already reviewed this school");
  }

  if (data.rating < 1 || data.rating > 5) {
    throw new ValidationError("Rating must be between 1 and 5");
  }

  const review = await db.review.create({
    data: {
      parentId: userId,
      schoolId: Number(schoolId),
      rating: data.rating,
      comment: data.comment,
      categoryTag: data.categoryTag,
    },
  });

  return review;
}

// ✅ Get reviews by school
export async function getReviewsBySchool(schoolId) {
  return db.review.findMany({
    where: { schoolId: Number(schoolId) },
    include: {
      parent: {
        select: { fullName: true },
      },
    },
  });
}

// ✅ Update review
export async function updateReview(userId, reviewId, data) {
  const review = await db.review.findUnique({
    where: { id: Number(reviewId) },
  });

  if (!review) throw new NotFoundError("Review not found");

  if (review.parentId !== userId) {
    throw new ForbiddenError("Not authorized to update this review");
  }

  return db.review.update({
    where: { id: review.id },
    data,
  });
}

// ✅ Delete review
export async function deleteReview(userId, reviewId) {
  const review = await db.review.findUnique({
    where: { id: Number(reviewId) },
  });

  if (!review) throw new NotFoundError("Review not found");

  if (review.parentId !== userId) {
    throw new ForbiddenError("Not authorized to delete this review");
  }

  await db.review.delete({
    where: { id: review.id },
  });

  return { message: "Review deleted" };
}
