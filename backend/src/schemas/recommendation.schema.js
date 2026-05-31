import { z } from "zod";
import { paginationQuery } from "./common.schema.js";

export const recommendationsQuerySchema = z.object({
  curriculum: z.enum(["LOCAL", "INTERNATIONAL"]).optional(),
  budget: z.coerce.number().nonnegative().optional(),
  minFee: z.coerce.number().nonnegative().optional(),
  maxFee: z.coerce.number().nonnegative().optional(),
  search: z.string().trim().optional(),
  schoolType: z.enum(["PRIVATE", "GOVERNMENT", "CHURCH"]).optional(),
  // Distance-scoring overrides. Without these, Zod's default-strip
  // behavior would silently drop them and the recommender would always fall
  // back to the parent's stored Parent.{lat,lng}.
  near: z
    .string()
    .regex(/^-?\d+(\.\d+)?,-?\d+(\.\d+)?$/, "near must be 'lat,lng'")
    .optional(),
  radiusKm: z.coerce.number().positive().max(1000).optional(),
  ...paginationQuery,
});
