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

export default router;
