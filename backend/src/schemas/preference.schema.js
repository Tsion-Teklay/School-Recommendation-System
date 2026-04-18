import { z } from "zod";

export const upsertPreferenceBodySchema = z
  .object({
    minBudget: z.coerce.number().nonnegative().optional(),
    maxBudget: z.coerce.number().nonnegative().optional(),
    curriculum: z.enum(["LOCAL", "INTERNATIONAL"]).optional(),
    distance: z.coerce.number().nonnegative().optional(),
  })
  .refine((val) => Object.keys(val).length > 0, {
    message: "At least one field is required",
  });
