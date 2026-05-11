import { z } from "zod";
import { paginationQuery } from "./common.schema.js";

/**
 * Phase 4 — comparisons.
 *
 * A parent compares 2–5 schools side by side. We deliberately enforce the
 * cap at the schema layer (and again in the service for callers that
 * bypass HTTP, e.g. tests) because the comparison view becomes unreadable
 * past 5 columns and the spec (UC07) caps at 5 too.
 */

const schoolIdsSchema = z
  .array(z.coerce.number().int().positive())
  .min(2, "Pick at least 2 schools to compare")
  .max(5, "Pick at most 5 schools to compare")
  .refine((ids) => new Set(ids).size === ids.length, {
    message: "Duplicate school ids are not allowed",
  });

export const createComparisonBodySchema = z.object({
  schoolIds: schoolIdsSchema,
  // Free-form list of metric names the client wants surfaced
  // (curriculum / tuitionFee / rating / distance / facilities / …).
  // Stored as a JSON-encoded string in metrics_used so we don't have to
  // migrate when the metric catalog grows.
  metrics: z.array(z.string().trim().min(1)).optional(),
});

export const listComparisonsQuerySchema = z.object({
  ...paginationQuery,
});
