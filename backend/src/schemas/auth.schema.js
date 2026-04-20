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

export const verifyEmailBodySchema = z.object({
  token: z.string().min(1).max(128),
});

export const resendVerificationBodySchema = z.object({
  email: z.string().trim().toLowerCase().email(),
});

export const forgotPasswordBodySchema = z.object({
  email: z.string().trim().toLowerCase().email(),
});

export const resetPasswordBodySchema = z.object({
  token: z.string().min(1).max(128),
  newPassword: z.string().min(6).max(255),
});

export const changePasswordBodySchema = z.object({
  currentPassword: z.string().min(1).max(255),
  newPassword: z.string().min(6).max(255),
});
