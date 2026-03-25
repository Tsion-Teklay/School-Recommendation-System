import {
  upsertPreference,
  getMyPreference,
} from "../services/preference.service.js";

// ✅ Create / Update
export async function savePreference(req, res) {
  try {
    // FIX: Changed req.user.userId to req.user.id
    const preference = await upsertPreference(req.user.id, req.body);

    res.json({
      message: "Preference saved successfully",
      preference,
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

// ✅ Get my preference
export async function getMy(req, res) {
  try {
    // FIX: Changed req.user.userId to req.user.id
    const preference = await getMyPreference(req.user.id);

    res.json({
      message: "Preference fetched successfully",
      preference,
    });
  } catch (err) {
    // Standardizing the error check like you did in School Controller
    res.status(404).json({ error: err.message });
  }
}