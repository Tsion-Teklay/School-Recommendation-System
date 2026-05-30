import { z } from "zod";

const targetTypeEnum = z.enum([
  "REVIEW",
  "SCHOOL",
  "ANNOUNCEMENT",
  "FORUM_POST",
]);
const reportStatusEnum = z.enum(["PENDING", "REVIEWED", "RESOLVED"]);

/**
 * Typed moderator actions. The action_type column is an
 * enum, so the schema must reject anything outside this set.
 */
const moderatorActionEnum = z.enum([
  "DISMISS",
  "REMOVE_CONTENT",
  "WARN_USER",
  "BAN_USER",
]);

export const createReportBodySchema = z.object({
  targetType: targetTypeEnum,
  targetId: z.coerce.number().int().positive(),
  reason: z.string().trim().min(1).max(255),
});

export const reportActionBodySchema = z.object({
  actionType: moderatorActionEnum,
  notes: z.string().trim().max(1000).optional(),
});

export const listReportsQuerySchema = z.object({
  status: reportStatusEnum.optional(),
});
