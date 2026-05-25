import { z } from "zod";  
  
/**
 * Multipart body — `documents` arrives as files via multer, not in the JSON
 * body. We only validate the optional text fields here.
 */
export const createAchievementBodySchema = z.object({
  description: z.string().trim().max(1000).optional(),
});  
  
export const reviewAchievementBodySchema = z.object({
  status: z.enum(["APPROVED", "REJECTED"]),
  reviewNotes: z.string().trim().max(500).optional().nullable(),
  tier: z.enum(["GOLD", "SILVER", "BRONZE"]).optional(),
}).refine((data) => {
  // If status is APPROVED, tier is required
  if (data.status === "APPROVED" && !data.tier) {
    return false;
  }
  return true;
}, {
  message: "Tier is required when approving an achievement",
  path: ["tier"],
});  
  
export const createStaffBreakdownBodySchema = z.object({  
  schoolId: z.coerce.number().int().positive(),  
  educationLevel: z.enum(["PHD", "MASTERS", "DEGREE", "DIPLOMA", "CERTIFICATE"]),  
  count: z.coerce.number().int().min(0),  
});  
  
export const updateStaffBreakdownBodySchema = z.object({  
  count: z.coerce.number().int().min(0),  
});