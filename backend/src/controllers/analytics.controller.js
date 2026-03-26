import {
  createAnalytics,
  getSchoolAnalytics,
  getDashboard,
} from "../services/analytics.service.js";

// ✅ Create
export async function create(req, res) {
  try {
    const data = await createAnalytics(req.body);

    res.status(201).json({
      message: "Analytics created",
      data,
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

// ✅ Get school analytics
export async function getSchool(req, res) {
  try {
    const data = await getSchoolAnalytics(req.params.id);

    res.json({
      message: "Analytics fetched",
      ...data,
    });
  } catch (err) {
    res.status(404).json({ error: err.message });
  }
}

// ✅ Dashboard
export async function dashboard(req, res) {
  try {
    const data = await getDashboard();

    res.json({
      message: "Dashboard data",
      ...data,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}