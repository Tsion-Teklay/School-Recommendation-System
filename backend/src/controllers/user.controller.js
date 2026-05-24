import { asyncHandler } from "../middlewares/async.middleware.js";
import { getMe, updateMe, deactivateMe, deleteMePermanently } from "../services/user.service.js";

export const me = asyncHandler(async (req, res) => {
  const user = await getMe(req.user.id);
  res.json({ user });
});

export const updateMeHandler = asyncHandler(async (req, res) => {
  const user = await updateMe(req.user.id, req.body);
  res.json({ message: "Profile updated", user });
});

export const deactivateMeHandler = asyncHandler(async (req, res) => {
  const user = await deactivateMe(req.user.id);
  res.json({ message: "Account deactivated", user });
});

export const deletePermanently = asyncHandler(async (req, res) => {  
  const result = await deleteMePermanently(req.user.id, req.body.password);  
  res.json(result);  
});