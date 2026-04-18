import { asyncHandler } from "../middlewares/async.middleware.js";
import { registerUser, loginUser } from "../services/auth.service.js";

export const register = asyncHandler(async (req, res) => {
  const user = await registerUser(req.body);
  res.status(201).json({
    message: "User registered successfully",
    user,
  });
});

export const login = asyncHandler(async (req, res) => {
  const { token, user } = await loginUser(req.body);
  res.json({
    message: "Login successful",
    token,
    user,
  });
});
