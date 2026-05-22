import express from "express";
import * as controller from "../controllers/report.controller.js";
import { authenticate } from "../middlewares/auth.middleware.js";
import { authorizeRoles } from "../middlewares/role.middleware.js";
import { validate } from "../middlewares/validate.middleware.js";
import { idParamsSchema } from "../schemas/common.schema.js";
import {
  createReportBodySchema,
  reportActionBodySchema,
  listReportsQuerySchema,
} from "../schemas/report.schema.js";

import { getReportedContent } from "../controllers/report.controller.js";

const router = express.Router();

/**
 * @openapi
 * /api/reports:
 *   post:
 *     tags: [Reports]
 *     summary: Submit a report (PARENT, SCHOOL_ADMIN, MOE_OFFICER)
 *     description: Moderators cannot submit reports — they review them.
 *     security: [{ bearerAuth: [] }]
 */
router.post(
  "/",
  authenticate,
  authorizeRoles("PARENT", "SCHOOL_ADMIN", "MOE_OFFICER"),
  validate({ body: createReportBodySchema }),
  controller.create
);

/**
 * @openapi
 * /api/reports:
 *   get:
 *     tags: [Reports]
 *     summary: List reports (MODERATOR only)
 *     security: [{ bearerAuth: [] }]
 */
router.get(
  "/",
  authenticate,
  authorizeRoles("MODERATOR"),
  validate({ query: listReportsQuerySchema }),
  controller.getAll
);

/**
 * @openapi
 * /api/reports/{id}:
 *   get:
 *     tags: [Reports]
 *     summary: Get one report (MODERATOR only)
 *     security: [{ bearerAuth: [] }]
 */
router.get(
  "/:id",
  authenticate,
  authorizeRoles("MODERATOR"),
  validate({ params: idParamsSchema }),
  controller.getOne
);

/**
 * @openapi
 * /api/reports/{id}/action:
 *   post:
 *     tags: [Reports]
 *     summary: Take moderation action (MODERATOR only)
 *     security: [{ bearerAuth: [] }]
 */
router.post(
  "/:id/action",
  authenticate,
  authorizeRoles("MODERATOR"),
  validate({ params: idParamsSchema, body: reportActionBodySchema }),
  controller.action
);

router.get(  
  "/:id/content",  
  authenticate,  
  authorizeRoles("MODERATOR"),  
  getReportedContent  
);

export default router;
