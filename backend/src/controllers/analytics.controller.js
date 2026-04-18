import { asyncHandler } from "../middlewares/async.middleware.js";
import {
  createAnalytics,
  getSchoolAnalytics,
  getDashboard,
} from "../services/analytics.service.js";

export const create = asyncHandler(async (req, res) => {
  const data = await createAnalytics(req.body);
  res.status(201).json({
    message: "Analytics created",
    data,
  });
});

export const getSchool = asyncHandler(async (req, res) => {
  const data = await getSchoolAnalytics(req.params.id);
  res.json({
    message: "Analytics fetched",
    ...data,
  });
});

export const dashboard = asyncHandler(async (req, res) => {
  const data = await getDashboard();
  res.json({
    message: "Dashboard data",
    ...data,
  });
});
