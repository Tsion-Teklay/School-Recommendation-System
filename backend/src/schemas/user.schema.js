import { z } from "zod";

export const updateMeBodySchema = z
  .object({
    fullName: z.string().trim().min(1).max(100).optional(),
    phone: z.string().trim().min(5).max(15).optional(),
  })
  .refine(
    (data) => Object.keys(data).length > 0,
    { message: "At least one field is required" }
  );
