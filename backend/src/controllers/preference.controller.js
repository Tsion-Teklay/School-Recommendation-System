import { asyncHandler } from "../middlewares/async.middleware.js";
import {
  upsertPreference,
  getMyPreference,
} from "../services/preference.service.js";

export const savePreference = asyncHandler(async (req, res) => {
  const preference = await upsertPreference(req.user.id, req.body);
  res.json({
    message: "Preference saved successfully",
    preference,
  });
});

export const getMy = asyncHandler(async (req, res) => {
  const preference = await getMyPreference(req.user.id);
  res.json({
    message: "Preference fetched successfully",
    preference,
  });
});
