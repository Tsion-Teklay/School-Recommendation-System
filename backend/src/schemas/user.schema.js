import { z } from "zod";

export const updateMeBodySchema = z
  .object({
    fullName: z.string().trim().min(1).max(100).optional(),
    phone: z.string().trim().regex(/^\+251[79]\d{8}$/, "Phone must be in format +2519xxxxxxxx or +2517xxxxxxxx").optional(),
  })
  .refine(
    (data) => Object.keys(data).length > 0,
    { message: "At least one field is required" }
  );
