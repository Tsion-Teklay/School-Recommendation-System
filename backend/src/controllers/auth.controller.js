import { asyncHandler } from "../middlewares/async.middleware.js";
import {
  registerUser,
  loginUser,
  verifyEmail,
  resendVerificationEmail,
  requestPasswordReset,
  resetPassword,
  changePassword,
  reactivateAccount,
} from "../services/auth.service.js";

export const register = asyncHandler(async (req, res) => {
  const user = await registerUser(req.body);
  res.status(201).json({
    message:
      "User registered. Check your email for a verification link before logging in.",
    user,
  });
});

export const login = asyncHandler(async (req, res) => {
  const { token, user } = await loginUser(req.body);
  res.json({ message: "Login successful", token, user });
});

export const verify = asyncHandler(async (req, res) => {
  const result = await verifyEmail(req.body);
  res.json({
    message: result.alreadyVerified
      ? "Email already verified"
      : "Email verified successfully",
  });
});

export const resend = asyncHandler(async (req, res) => {
  await resendVerificationEmail(req.body);
  // Always 200 — do not leak whether the email exists.
  res.json({
    message:
      "If that email belongs to an unverified account, a new verification link was sent.",
  });
});

export const forgotPassword = asyncHandler(async (req, res) => {
  await requestPasswordReset(req.body);
  res.json({
    message:
      "If that email belongs to an active account, a password reset link was sent.",
  });
});

export const resetPasswordHandler = asyncHandler(async (req, res) => {
  await resetPassword(req.body);
  res.json({ message: "Password reset successfully" });
});

export const changePasswordHandler = asyncHandler(async (req, res) => {
  await changePassword({ userId: req.user.id, ...req.body });
  res.json({ message: "Password changed successfully" });
});

export const reactivate = asyncHandler(async (req, res) => {  
  const result = await reactivateAccount(req.body);  
  res.json(result);  
});  
