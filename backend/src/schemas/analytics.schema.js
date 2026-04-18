import { z } from "zod";

export const createAnalyticsBodySchema = z.object({
  schoolId: z.coerce.number().int().positive(),
  metricType: z.string().trim().min(1).max(50),
  metricValue: z.coerce.number(),
  academicYear: z.coerce.number().int().min(1900).max(2100),
  source: z.string().trim().min(1).max(100),
});
