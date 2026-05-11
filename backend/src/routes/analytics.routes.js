import express from "express";
import * as controller from "../controllers/analytics.controller.js";
import { authenticate } from "../middlewares/auth.middleware.js";
import { authorizeRoles } from "../middlewares/role.middleware.js";
import { validate } from "../middlewares/validate.middleware.js";
import { idParamsSchema } from "../schemas/common.schema.js";
import { createAnalyticsBodySchema } from "../schemas/analytics.schema.js";

const router = express.Router();

/**
 * @openapi
 * /api/analytics/school/{id}:
 *   get:
 *     tags: [Analytics]
 *     summary: Analytics for a single school (public)
 */
router.get(
  "/school/:id",
  validate({ params: idParamsSchema }),
  controller.getSchool
);

/**
 * @openapi
 * /api/analytics:
 *   post:
 *     tags: [Analytics]
 *     summary: Record analytics data (MOE_OFFICER or SCHOOL_ADMIN)
 *     security: [{ bearerAuth: [] }]
 */
router.post(
  "/",
  authenticate,
  authorizeRoles("MOE_OFFICER", "SCHOOL_ADMIN"),
  validate({ body: createAnalyticsBodySchema }),
  controller.create
);

/**
 * @openapi
 * /api/analytics/dashboard:
 *   get:
 *     tags: [Analytics]
 *     summary: MoE ministry dashboard (MOE_OFFICER only)
 *     security: [{ bearerAuth: [] }]
 */
router.get(
  "/dashboard",
  authenticate,
  authorizeRoles("MOE_OFFICER"),
  controller.dashboard
);

/**
 * @openapi
 * /api/analytics/dashboard.csv:
 *   get:
 *     tags: [Analytics]
 *     summary: Phase 6 — same dashboard payload, CSV-flattened (MOE_OFFICER only)
 *     description: |
 *       Returns the dashboard summary, group counts, top schools, and most
 *       followed schools as a multi-section CSV suitable for opening in
 *       Excel/Sheets. Same RBAC as `/dashboard`.
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200:
 *         description: CSV file
 *         content:
 *           text/csv: {}
 */
router.get(
  "/dashboard.csv",
  authenticate,
  authorizeRoles("MOE_OFFICER"),
  controller.dashboardCsv
);

export default router;
