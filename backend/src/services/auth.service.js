import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import { db } from "../config/db.js";
import { sendMail } from "../config/mailer.js";
import { logger } from "../config/logger.js";
import {
  ConflictError,
  NotFoundError,
  UnauthorizedError,
  ValidationError,
} from "../utils/errors.js";
import {
  EMAIL_VERIFICATION_TTL_MS,
  PASSWORD_RESET_TTL_MS,
  expiresAt,
  generateToken,
} from "../utils/tokens.js";

const SALT_ROUNDS = 10;

// 🔒 strip every sensitive field before returning user
function sanitizeUser(user) {
  const {
    password,
    emailVerificationToken,
    emailVerificationExpires,
    passwordResetToken,
    passwordResetExpires,
    ...safeUser
  } = user;
  return safeUser;
}

function signToken(user) {
  return jwt.sign(
    { userId: user.id, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || "1d" }
  );
}

// Best-effort: swallow mail failures so the request still succeeds if SMTP
// is temporarily unavailable. Users can always re-request verification/reset.
async function sendMailSafe(payload, logCtx) {
  try {
    await sendMail(payload);
  } catch (err) {
    logger.warn({ err, ...logCtx }, "Email delivery failed");
  }
}

function appBaseUrl() {
  return process.env.APP_URL || "http://localhost:5050";
}

// -----------------------------------------------------------------------------
// Register + verify email
// -----------------------------------------------------------------------------

export async function registerUser({ fullName, email, phone, password, role }) {
  if (!fullName || !email || !password || !role) {
    throw new ValidationError("Missing required fields");
  }

  const normalizedEmail = email.toLowerCase();
  const existing = await db.user.findUnique({ where: { email: normalizedEmail } });
  if (existing) throw new ConflictError("Email already registered");

  const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);
  const verificationToken = generateToken();

  const user = await db.user.create({
    data: {
      fullName,
      email: normalizedEmail,
      phone,
      password: hashedPassword,
      accountStatus: "ACTIVE",
      role,
      emailVerified: false,
      emailVerificationToken: verificationToken,
      emailVerificationExpires: expiresAt(EMAIL_VERIFICATION_TTL_MS),
    },
  });

  await sendMailSafe(
    {
      to: normalizedEmail,
      subject: "Verify your School Recommendation account",
      text:
        `Hi ${fullName},\n\n` +
        `Welcome! Please verify your email by visiting:\n` +
        `${appBaseUrl()}/verify-email?token=${verificationToken}\n\n` +
        `Or POST the token to /api/auth/verify-email. The link expires in 24 hours.`,
    },
    { event: "register", userId: user.id }
  );

  return sanitizeUser(user);
}

export async function verifyEmail({ token }) {
  if (!token) throw new ValidationError("Verification token is required");

  const user = await db.user.findUnique({
    where: { emailVerificationToken: token },
  });
  if (!user) throw new ValidationError("Invalid verification token");

  if (user.emailVerificationExpires && user.emailVerificationExpires < new Date()) {
    throw new ValidationError("Verification token has expired");
  }

  if (user.emailVerified) {
    // Idempotent — clear any stale token anyway.
    await db.user.update({
      where: { id: user.id },
      data: { emailVerificationToken: null, emailVerificationExpires: null },
    });
    return { alreadyVerified: true };
  }

  await db.user.update({
    where: { id: user.id },
    data: {
      emailVerified: true,
      emailVerificationToken: null,
      emailVerificationExpires: null,
    },
  });
  return { alreadyVerified: false };
}

export async function resendVerificationEmail({ email }) {
  const normalizedEmail = email.toLowerCase();
  const user = await db.user.findUnique({ where: { email: normalizedEmail } });

  // Do not leak which addresses exist — always return success-shaped payload.
  if (!user || user.emailVerified) return { sent: false };

  const verificationToken = generateToken();
  await db.user.update({
    where: { id: user.id },
    data: {
      emailVerificationToken: verificationToken,
      emailVerificationExpires: expiresAt(EMAIL_VERIFICATION_TTL_MS),
    },
  });

  await sendMailSafe(
    {
      to: normalizedEmail,
      subject: "Verify your School Recommendation account",
      text:
        `Hi ${user.fullName},\n\n` +
        `Here is a fresh verification link (expires in 24 hours):\n` +
        `${appBaseUrl()}/verify-email?token=${verificationToken}`,
    },
    { event: "resend_verification", userId: user.id }
  );
  return { sent: true };
}

// -----------------------------------------------------------------------------
// Login
// -----------------------------------------------------------------------------

export async function loginUser({ email, password }) {
  if (!email || !password) {
    throw new ValidationError("Email and password are required");
  }

  const normalizedEmail = email.toLowerCase();
  const user = await db.user.findUnique({ where: { email: normalizedEmail } });

  if (!user) throw new UnauthorizedError("Invalid credentials");

  if (user.accountStatus !== "ACTIVE") {
    throw new UnauthorizedError("Account is deactivated");
  }

  const match = await bcrypt.compare(password, user.password);
  if (!match) throw new UnauthorizedError("Invalid credentials");

  if (!user.emailVerified) {
    // Distinct code so the frontend can prompt "resend verification".
    const err = new UnauthorizedError("Email not verified");
    err.code = "EMAIL_NOT_VERIFIED";
    throw err;
  }

  return { token: signToken(user), user: sanitizeUser(user) };
}

// -----------------------------------------------------------------------------
// Forgot / reset password
// -----------------------------------------------------------------------------

export async function requestPasswordReset({ email }) {
  const normalizedEmail = email.toLowerCase();
  const user = await db.user.findUnique({ where: { email: normalizedEmail } });

  // Do not leak existence — always act like success.
  if (!user || user.accountStatus !== "ACTIVE") return { sent: false };

  const resetToken = generateToken();
  await db.user.update({
    where: { id: user.id },
    data: {
      passwordResetToken: resetToken,
      passwordResetExpires: expiresAt(PASSWORD_RESET_TTL_MS),
    },
  });

  await sendMailSafe(
    {
      to: normalizedEmail,
      subject: "Reset your School Recommendation password",
      text:
        `Hi ${user.fullName},\n\n` +
        `Someone (hopefully you) asked to reset your password.\n` +
        `Use this link within 1 hour:\n` +
        `${appBaseUrl()}/reset-password?token=${resetToken}\n\n` +
        `If you didn't request this, ignore this email.`,
    },
    { event: "forgot_password", userId: user.id }
  );
  return { sent: true };
}

export async function resetPassword({ token, newPassword }) {
  if (!token || !newPassword) {
    throw new ValidationError("Token and newPassword are required");
  }

  const user = await db.user.findUnique({ where: { passwordResetToken: token } });
  if (!user) throw new ValidationError("Invalid reset token");
  if (user.passwordResetExpires && user.passwordResetExpires < new Date()) {
    throw new ValidationError("Reset token has expired");
  }

  const hashed = await bcrypt.hash(newPassword, SALT_ROUNDS);
  await db.user.update({
    where: { id: user.id },
    data: {
      password: hashed,
      passwordResetToken: null,
      passwordResetExpires: null,
    },
  });
}

// -----------------------------------------------------------------------------
// Change password (authenticated)
// -----------------------------------------------------------------------------

export async function changePassword({ userId, currentPassword, newPassword }) {
  if (!currentPassword || !newPassword) {
    throw new ValidationError("currentPassword and newPassword are required");
  }
  if (currentPassword === newPassword) {
    throw new ValidationError("New password must differ from current password");
  }

  const user = await db.user.findUnique({ where: { id: userId } });
  if (!user) throw new NotFoundError("User not found");

  const match = await bcrypt.compare(currentPassword, user.password);
  if (!match) throw new UnauthorizedError("Current password is incorrect");

  const hashed = await bcrypt.hash(newPassword, SALT_ROUNDS);
  await db.user.update({ where: { id: userId }, data: { password: hashed } });
}
