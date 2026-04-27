import { z } from "zod";
import { paginationQuery } from "./common.schema.js";

const curriculumEnum = z.enum(["LOCAL", "INTERNATIONAL"]);

export const createSchoolBodySchema = z.object({
  schoolName: z.string().trim().min(1).max(100),
  address: z.string().trim().min(1).max(255),
  contactEmail: z.string().trim().toLowerCase().email().max(100),
  contactPhone: z.string().trim().min(5).max(15).optional(),
  curriculum: curriculumEnum,
  tuitionFee: z.coerce.number().nonnegative(),
  facilities: z.string().optional(),
  latitude: z.coerce.number().min(-90).max(90).optional(),
  longitude: z.coerce.number().min(-180).max(180).optional(),
});

export const updateSchoolBodySchema = createSchoolBodySchema
  .partial()
  .refine((val) => Object.keys(val).length > 0, {
    message: "At least one field is required",
  });

export const listSchoolsQuerySchema = z.object({
  search: z.string().trim().optional(),
  curriculum: curriculumEnum.optional(),
  minFee: z.coerce.number().nonnegative().optional(),
  maxFee: z.coerce.number().nonnegative().optional(),
  // Phase 4: proximity search.
  // `near` is a "lat,lng" string. Validated here for shape; the service
  // re-parses and bounds-checks the numeric ranges so the same guard fires
  // for non-HTTP callers too.
  near: z
    .string()
    .trim()
    .regex(/^-?\d+(\.\d+)?,-?\d+(\.\d+)?$/, "near must be 'lat,lng'")
    .optional(),
  radiusKm: z.coerce.number().positive().max(20000).optional(),
  ...paginationQuery,
});
