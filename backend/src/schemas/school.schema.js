import { z } from "zod";
import { paginationQuery } from "./common.schema.js";

const curriculumEnum = z.enum(["LOCAL", "INTERNATIONAL"]);
// Phase 11 — must stay in sync with the Prisma `SchoolLevel` enum.
const schoolLevelEnum = z.enum(["PRE_PRIMARY", "PRIMARY", "SECONDARY"]);
const schoolTypeEnum = z.enum(["PRIVATE", "GOVERNMENT", "CHURCH"]);

export const createSchoolBodySchema = z.object({
  schoolName: z.string().trim().min(1, "School name is required").max(100, "School name must be less than 100 characters"),
  subCity: z.enum(["ADDIS_KETEMA", "AKALI_KALTI", "ARADA", "BOLE", "GULELE", "KOLFE_KERANIO", "KIRKOS", "LIDETA", "NIFAS_SILK_LAFTO", "YEKKA"]).nullable().optional(),
  woreda: z.string().trim().max(20, "Woreda must be less than 20 characters").nullable().optional(),
  streetName: z.string().trim().max(100, "Street name must be less than 100 characters").nullable().optional(),
  contactEmail: z.string().trim().toLowerCase().email("Invalid email format").max(100, "Email must be less than 100 characters"),
  contactPhone: z.string().trim().min(5, "Phone number must be at least 5 characters").max(15, "Phone number must be less than 15 characters").nullable().optional(),
  curriculum: curriculumEnum,
  // Optional on the wire — the column is nullable in the schema so legacy
  // schools without a level still validate.
  schoolLevel: schoolLevelEnum.nullable().optional(),
  schoolType: schoolTypeEnum.nullable().optional(),
  tuitionFee: z.coerce.number().nonnegative("Tuition fee must be a valid number (0 or greater)"),
  facilities: z.string().nullable().optional(),
  latitude: z.coerce.number().min(-90, "Latitude must be between -90 and 90").max(90, "Latitude must be between -90 and 90").nullable().optional(),
  longitude: z.coerce.number().min(-180, "Longitude must be between -180 and 180").max(180, "Longitude must be between -180 and 180").nullable().optional(),
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
  subCity: z.enum(["ADDIS_KETEMA", "AKALI_KALTI", "ARADA", "BOLE", "GULELE", "KOLFE_KERANIO", "KIRKOS", "LIDETA", "NIFAS_SILK_LAFTO", "YEKKA"]).nullable().optional(),
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

export const revokeVerificationBodySchema = z.object({
  reason: z.string().trim().min(1, "Reason is required").max(500, "Reason must be less than 500 characters"),
});
