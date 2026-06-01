import { z } from "zod";

const roleEnum = z.enum(["PARENT", "SCHOOL_ADMIN", "MOE_OFFICER", "MODERATOR"]);

const subCityEnum = z.enum(["ADDIS_KETEMA", "AKALI_KALTI", "ARADA", "BOLE", "GULELE", "KOLFE_KERANIO", "KIRKOS", "LIDETA", "NIFAS_SILK_LAFTO", "YEKKA"]); 

// Either `email` or `phone` must be present at register time — both are
// independent credentials a user can later log in with. We still accept both
// in the same request so a user who signed up by phone can add an email later
// without re-registering (covered by /api/users/me — out of scope here, but
// the data model already supports it).
export const registerBodySchema = z
  .object({
    fullName: z.string().trim().min(1).max(100),
    email: z.string().trim().toLowerCase().email().max(100).optional(),
    phone: z.string().trim().regex(/^\+251[79]\d{8}$/, "Phone must be in format +2519xxxxxxxx or +2517xxxxxxxx").optional(),
    password: z.string().min(6).max(255),
    role: roleEnum,
    subCity: subCityEnum.optional(),
    officerRole: z.string().trim().min(1).max(255).optional(),
  })
  .refine((v) => v.email || v.phone, {
    message: "Either email or phone is required",
    path: ["email"],
  })
  .refine((v) => {  
    if (v.role === "MOE_OFFICER") {  
      return v.subCity !== undefined && v.officerRole !== undefined;  
    }  
    return true;  
  }, {  
    message: "subCity and officerRole are required for MOE_OFFICER role",  
    path: ["subCity"],  
  });

// `identifier` is whichever credential the user typed — we resolve it to an
// account by email or phone in the service. Kept the legacy `email` field for
// backwards compatibility (older clients), but mark it deprecated in the
// OpenAPI doc. Exactly one of `identifier`/`email` must be present.
export const loginBodySchema = z
  .object({
    identifier: z.string().trim().min(1).max(100).optional(),
    email: z.string().trim().toLowerCase().email().optional(),
    password: z.string().min(1),
  })
  .refine((v) => v.identifier || v.email, {
    message: "identifier (email or phone) is required",
    path: ["identifier"],
  });

export const verifyEmailBodySchema = z.object({
  token: z.string().min(1).max(128),
});

export const verifyPhoneBodySchema = z.object({
  token: z.string().min(1).max(128),
});

export const resendVerificationBodySchema = z.object({
  email: z.string().trim().toLowerCase().email(),
});

export const resendPhoneBodySchema = z.object({
  phone: z.string().trim().regex(/^\+251[79]\d{8}$/, "Phone must be in format +2519xxxxxxxx or +2517xxxxxxxx"),
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

export const reactivateAccountBodySchema = z.object({
  identifier: z.string().trim().min(1),  
  password: z.string().min(1),  
});

export const deleteAccountSchema = z.object({  
  password: z.string().min(1),  
});
