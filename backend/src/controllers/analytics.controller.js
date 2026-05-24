import { asyncHandler } from "../middlewares/async.middleware.js";
import {
  createAnalytics,
  getSchoolAnalytics,
  getSchoolCompositeAnalytics,
  getDashboard,
  getDashboardCsv,
} from "../services/analytics.service.js";

export const create = asyncHandler(async (req, res) => {
  const data = await createAnalytics(req.body);
  res.status(201).json({
    message: "Analytics created",
    data,
  });
});

export const getSchool = asyncHandler(async (req, res) => {    
  const { schoolId } = req.params;    
  const result = await getSchoolCompositeAnalytics(Number(schoolId));    
  res.json(result);    
});  

export const dashboard = asyncHandler(async (req, res) => {
  const data = await getDashboard();
  res.json({
    message: "Dashboard data",
    ...data,
  });
});

/**
 * Phase 6 — CSV export of the same dashboard payload.
 *
 * Filename includes today's date so MoE officers downloading multiple times
 * don't overwrite previous exports in their downloads folder.
 */
export const dashboardCsv = asyncHandler(async (req, res) => {
  const csv = await getDashboardCsv();
  const today = new Date().toISOString().slice(0, 10);
  res.setHeader("Content-Type", "text/csv; charset=utf-8");
  res.setHeader(
    "Content-Disposition",
    `attachment; filename="moe-dashboard-${today}.csv"`
  );
  res.send(csv);
});
