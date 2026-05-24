import { z } from "zod";
import { paginationQuery } from "./common.schema.js";

const curriculumEnum = z.enum(["LOCAL", "INTERNATIONAL"]);
// Phase 11 — must stay in sync with the Prisma `SchoolLevel` enum.
const schoolLevelEnum = z.enum(["PRE_PRIMARY", "PRIMARY", "SECONDARY"]);
const schoolTypeEnum = z.enum(["PRIVATE", "GOVERNMENT", "CHURCH"]);

export const createSchoolBodySchema = z.object({
  schoolName: z.string().trim().min(1).max(100),
  subCity: z.enum(["ADDIS_KETEMA", "AKALI_KALTI", "ARADA", "BOLE", "GULELE", "KOLFE_KERANIO", "KIRKOS", "LIDETA", "NIFAS_SILK_LAFTO", "YEKKA"]).optional(),  
  woreda: z.string().trim().max(20).optional(),  
  streetName: z.string().trim().max(100).optional(),  
  contactEmail: z.string().trim().toLowerCase().email().max(100),
  contactPhone: z.string().trim().min(5).max(15).optional(),
  curriculum: curriculumEnum,
  // Optional on the wire — the column is nullable in the schema so legacy
  // schools without a level still validate.
  schoolLevel: schoolLevelEnum.optional(),
  schoolType: schoolTypeEnum.optional(),
  tuitionFee: z.coerce.number().nonnegative(),
  facilities: z.string().optional(),
  latitude: z.coerce.number().min(-90).max(90).optional(),
  longitude: z.coerce.number().min(-180).max(180).optional(),
});

export const updateSchoolBodySchema = createSchoolBodySchema
  .partial()
  // Allow clearing the nullable fields explicitly (PUT with `field: null`);
  // `.partial()` already accepts the field being absent.
  .extend({
    subCity: z.enum(["ADDIS_KETEMA", "AKALI_KALTI", "ARADA", "BOLE", "GULELE", "KOLFE_KERANIO", "KIRKOS", "LIDETA", "NIFAS_SILK_LAFTO", "YEKKA"]).nullable().optional(),  
    woreda: z.string().trim().max(20).nullable().optional(),  
    streetName: z.string().trim().max(100).nullable().optional(),  
    schoolLevel: schoolLevelEnum.nullable().optional(),
    schoolType: schoolTypeEnum.nullable().optional(),
  })
  .refine((val) => Object.keys(val).length > 0, {
    message: "At least one field is required",
  });

export const listSchoolsQuerySchema = z.object({
  search: z.string().trim().optional(),
  curriculum: curriculumEnum.optional(),
  // Phase 11 — new filter chip on the schools list.
  schoolLevel: schoolLevelEnum.optional(),
  schoolType: schoolTypeEnum.optional(),
  minFee: z.coerce.number().nonnegative().optional(),
  maxFee: z.coerce.number().nonnegative().optional(),
  // Phase 11 — "stars and up" filter. Decimal so the UI can pass values like
  // 4.5 if it ever wants half-star precision.
  minRating: z.coerce.number().min(0).max(5).optional(),
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
