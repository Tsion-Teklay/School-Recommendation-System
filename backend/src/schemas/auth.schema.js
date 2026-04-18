import { z } from "zod";

const roleEnum = z.enum(["PARENT", "SCHOOL_ADMIN", "MOE_OFFICER", "MODERATOR"]);

export const registerBodySchema = z.object({
  fullName: z.string().trim().min(1).max(100),
  email: z.string().trim().toLowerCase().email().max(100),
  phone: z.string().trim().min(5).max(15).optional(),
  password: z.string().min(6).max(255),
  role: roleEnum,
});

export const loginBodySchema = z.object({
  email: z.string().trim().toLowerCase().email(),
  password: z.string().min(1),
});
