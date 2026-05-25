import express from "express";
import {
  register,
  login,
  verify,
  resend,
  forgotPassword,
  resetPasswordHandler,
  changePasswordHandler,
  reactivate,
  verifyPhone,
  resendPhone,
} from "../controllers/auth.controller.js";
import { authenticate } from "../middlewares/auth.middleware.js";
import { validate } from "../middlewares/validate.middleware.js";
import {
  registerBodySchema,
  loginBodySchema,
  verifyEmailBodySchema,
  verifyPhoneBodySchema,
  resendVerificationBodySchema,
  resendPhoneBodySchema,
  forgotPasswordBodySchema,
  resetPasswordBodySchema,
  changePasswordBodySchema,
  reactivateAccountBodySchema,
} from "../schemas/auth.schema.js";

const router = express.Router();

/**
 * @openapi
 * /api/auth/register:
 *   post:
 *     tags: [Auth]
 *     summary: Register a new user
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [fullName, password, role]
 *             description: |
 *               At least one of `email` or `phone` must be supplied. Phone-only
 *               signups skip the email-verification gate (the account is
 *               created already-verified). Email signups still receive a
 *               verification link.
 *             properties:
 *               fullName: { type: string }
 *               email: { type: string, format: email }
 *               phone: { type: string }
 *               password: { type: string, minLength: 6 }
 *               role:
 *                 type: string
 *                 enum: [PARENT, SCHOOL_ADMIN, MOE_OFFICER, MODERATOR]
 *     responses:
 *       201: { description: User created }
 *       400: { description: Validation error }
 *       409: { description: Email or phone already registered }
 */
router.post("/register", validate({ body: registerBodySchema }), register);

/**
 * @openapi
 * /api/auth/login:
 *   post:
 *     tags: [Auth]
 *     summary: Log in and receive a JWT (accepts email OR phone)
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [password]
 *             description: |
 *               Send either `identifier` (an email address or a phone number)
 *               or the legacy `email` field. Phone is matched verbatim against
 *               the stored value (no normalization).
 *             properties:
 *               identifier: { type: string, description: "Email or phone" }
 *               email: { type: string, format: email, deprecated: true }
 *               password: { type: string }
 *     responses:
 *       200: { description: JWT issued }
 *       401: { description: Invalid credentials or account deactivated }
 */
router.post("/login", validate({ body: loginBodySchema }), login);

/**
 * @openapi
 * /api/auth/reactivate:
 *   post:
 *     tags: [Auth]
 *     summary: Reactivate a self-deactivated account
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [identifier, password]
 *             properties:
 *               identifier: { type: string }
 *               password: { type: string }
 *     responses:
 *       200: { description: Account reactivated, JWT issued }
 *       401: { description: Invalid credentials or account not self-deactivated }
 */
router.post(
  "/reactivate",
  validate({ body: reactivateAccountBodySchema }),
  reactivate,
);

/**
 * @openapi
 * /api/auth/verify-email:
 *   post:
 *     tags: [Auth]
 *     summary: Verify a user's email using a token
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [token]
 *             properties:
 *               token: { type: string }
 *     responses:
 *       200: { description: Email verified }
 *       400: { description: Invalid or expired token }
 */
router.post("/verify-email", validate({ body: verifyEmailBodySchema }), verify);

router.post(
  "/verify-phone",
  validate({ body: verifyPhoneBodySchema }),
  verifyPhone,
);

/**
 * @openapi
 * /api/auth/resend-verification:
 *   post:
 *     tags: [Auth]
 *     summary: Resend a verification email
 *     description: Always responds 200 — we do not leak whether the email is registered.
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email]
 *             properties:
 *               email: { type: string, format: email }
 *     responses:
 *       200: { description: If the email exists and is unverified, a new link was sent }
 */
router.post(
  "/resend-verification",
  validate({ body: resendVerificationBodySchema }),
  resend,
);

router.post(
  "/resend-phone-verification",
  validate({ body: resendPhoneBodySchema }),
  resendPhone,
);

/**
 * @openapi
 * /api/auth/forgot-password:
 *   post:
 *     tags: [Auth]
 *     summary: Request a password reset link
 *     description: Always responds 200 — we do not leak whether the email is registered.
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email]
 *             properties:
 *               email: { type: string, format: email }
 *     responses:
 *       200: { description: If the email belongs to an active account, a reset link was sent }
 */
router.post(
  "/forgot-password",
  validate({ body: forgotPasswordBodySchema }),
  forgotPassword,
);

/**
 * @openapi
 * /api/auth/reset-password:
 *   post:
 *     tags: [Auth]
 *     summary: Reset a user's password using a reset token
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [token, newPassword]
 *             properties:
 *               token: { type: string }
 *               newPassword: { type: string, minLength: 6 }
 *     responses:
 *       200: { description: Password reset successfully }
 *       400: { description: Invalid or expired token }
 */
router.post(
  "/reset-password",
  validate({ body: resetPasswordBodySchema }),
  resetPasswordHandler,
);

/**
 * @openapi
 * /api/auth/change-password:
 *   post:
 *     tags: [Auth]
 *     summary: Change the authenticated user's password
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [currentPassword, newPassword]
 *             properties:
 *               currentPassword: { type: string }
 *               newPassword: { type: string, minLength: 6 }
 *     responses:
 *       200: { description: Password changed successfully }
 *       400: { description: New password must differ from current }
 *       401: { description: Current password is incorrect or missing JWT }
 */
router.post(
  "/change-password",
  authenticate,
  validate({ body: changePasswordBodySchema }),
  changePasswordHandler,
);

export default router;
