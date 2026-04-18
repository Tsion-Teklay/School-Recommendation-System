import { z } from "zod";

const targetTypeEnum = z.enum(["REVIEW", "SCHOOL", "ANNOUNCEMENT"]);
const reportStatusEnum = z.enum(["PENDING", "REVIEWED", "DISMISSED"]);

export const createReportBodySchema = z.object({
  targetType: targetTypeEnum,
  targetId: z.coerce.number().int().positive(),
  reason: z.string().trim().min(1).max(255),
});

export const reportActionBodySchema = z.object({
  actionType: z.string().trim().min(1).max(50),
  notes: z.string().trim().max(1000).optional(),
});

export const listReportsQuerySchema = z.object({
  status: reportStatusEnum.optional(),
});
