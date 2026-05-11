import { z } from "zod";

// Phase 2: added FACILITIES + AFFORDABILITY to match the spec scenarios.
const categoryTagEnum = z.enum([
  "SAFETY",
  "TEACHING_QUALITY",
  "FACILITIES",
  "AFFORDABILITY",
  "OTHER",
]);

export const createReviewBodySchema = z.object({
  rating: z.coerce.number().int().min(1).max(5),
  comment: z.string().trim().min(1).max(1000).optional(),
  categoryTag: categoryTagEnum,
});

export const updateReviewBodySchema = z
  .object({
    rating: z.coerce.number().int().min(1).max(5).optional(),
    comment: z.string().trim().min(1).max(1000).optional(),
    categoryTag: categoryTagEnum.optional(),
  })
  .refine((val) => Object.keys(val).length > 0, {
    message: "At least one field is required",
  });
