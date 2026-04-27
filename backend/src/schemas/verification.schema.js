import { z } from "zod";
import { paginationQuery } from "./common.schema.js";

export const verificationRequestStatusEnum = z.enum([
  "PENDING",
  "APPROVED",
  "REJECTED",
]);

/**
 * Multipart body — `documents` arrives as files via multer, not in the JSON
 * body. We only validate the optional text fields here.
 */
export const submitVerificationBodySchema = z.object({
  notes: z.string().trim().max(1000).optional(),
});

export const reviewVerificationBodySchema = z.object({
  status: z.enum(["APPROVED", "REJECTED"]),
  reviewNotes: z.string().trim().max(1000).optional(),
});

export const listVerificationQuerySchema = z.object({
  status: verificationRequestStatusEnum.optional(),
  schoolId: z.coerce.number().int().positive().optional(),
  ...paginationQuery,
});
