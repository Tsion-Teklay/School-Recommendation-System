import { z } from "zod";  
  
export const createAchievementBodySchema = z.object({  
  schoolId: z.coerce.number().int().positive(),  
  title: z.string().trim().min(1).max(150),  
  description: z.string().trim().max(1000).optional().nullable(),  
  tier: z.enum(["GOLD", "SILVER", "BRONZE"]),  
  year: z.coerce.number().int().min(2000).max(2100),  
  documents: z.array(z.string().url()).optional().nullable(),  
});  
  
export const reviewAchievementBodySchema = z.object({  
  status: z.enum(["APPROVED", "REJECTED"]),  
  reviewNotes: z.string().trim().max(500).optional().nullable(),  
});  
  
export const createStaffBreakdownBodySchema = z.object({  
  schoolId: z.coerce.number().int().positive(),  
  educationLevel: z.enum(["PHD", "MASTERS", "DEGREE", "DIPLOMA", "CERTIFICATE"]),  
  count: z.coerce.number().int().min(0),  
});  
  
export const updateStaffBreakdownBodySchema = z.object({  
  count: z.coerce.number().int().min(0),  
});