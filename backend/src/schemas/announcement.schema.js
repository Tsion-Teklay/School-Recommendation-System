import { z } from "zod";
import { paginationQuery } from "./common.schema.js";

const categoryEnum = z.enum(["ADMISSIONS", "POLICY", "FEE", "OTHER"]);
const urgencyEnum = z.enum(["NORMAL", "HIGH", "EMERGENCY"]);

export const createAnnouncementBodySchema = z.object({
  title: z.string().trim().min(1).max(200),
  content: z.string().trim().min(1),
  category: categoryEnum,
  urgencyLevel: urgencyEnum.default("NORMAL"),
  schoolId: z.coerce.number().int().positive().optional(),
});

export const updateAnnouncementBodySchema = createAnnouncementBodySchema
  .partial()
  .refine((val) => Object.keys(val).length > 0, {
    message: "At least one field is required",
  });

export const listAnnouncementsQuerySchema = z.object({
  category: categoryEnum.optional(),
  urgencyLevel: urgencyEnum.optional(),
  // Phase 11 — when set, narrows the feed to a single school. Useful both for
  // the "recent announcements on school detail" widget and for the parents'
  // global feed (where the UI sometimes lets them pin a school).
  schoolId: z.coerce.number().int().positive().optional(),
  // Phase 11 — "followedOnly=true" returns only posts from schools the
  // logged-in parent currently subscribes to. Backend ignores this flag for
  // unauthenticated callers (the service rechecks auth).
  followedOnly: z
    .union([z.literal("true"), z.literal("false"), z.boolean()])
    .optional()
    .transform((v) => v === true || v === "true"),
  ...paginationQuery,
});
