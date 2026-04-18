import express from "express";
import {
  create,
  getAll,
  getOne,
  update,
  remove,
} from "../controllers/announcement.controller.js";
import { authenticate } from "../middlewares/auth.middleware.js";
import { authorizeRoles } from "../middlewares/role.middleware.js";
import { validate } from "../middlewares/validate.middleware.js";
import { idParamsSchema } from "../schemas/common.schema.js";
import {
  createAnnouncementBodySchema,
  updateAnnouncementBodySchema,
  listAnnouncementsQuerySchema,
} from "../schemas/announcement.schema.js";

const router = express.Router();

/**
 * @openapi
 * /api/announcements:
 *   get:
 *     tags: [Announcements]
 *     summary: List announcements (public)
 *     parameters:
 *       - in: query
 *         name: category
 *         schema: { type: string, enum: [ADMISSIONS, POLICY, FEE, OTHER] }
 *       - in: query
 *         name: urgencyLevel
 *         schema: { type: string, enum: [NORMAL, HIGH, EMERGENCY] }
 *     responses:
 *       200: { description: Paginated list }
 */
router.get("/", validate({ query: listAnnouncementsQuerySchema }), getAll);

/**
 * @openapi
 * /api/announcements/{id}:
 *   get:
 *     tags: [Announcements]
 *     summary: Get one announcement (public)
 */
router.get("/:id", validate({ params: idParamsSchema }), getOne);

/**
 * @openapi
 * /api/announcements/school:
 *   post:
 *     tags: [Announcements]
 *     summary: Publish a school-level announcement (SCHOOL_ADMIN only)
 *     security: [{ bearerAuth: [] }]
 */
router.post(
  "/school",
  authenticate,
  authorizeRoles("SCHOOL_ADMIN"),
  validate({ body: createAnnouncementBodySchema }),
  create
);

/**
 * @openapi
 * /api/announcements/moe:
 *   post:
 *     tags: [Announcements]
 *     summary: Publish a ministry-level announcement (MOE_OFFICER only)
 *     security: [{ bearerAuth: [] }]
 */
router.post(
  "/moe",
  authenticate,
  authorizeRoles("MOE_OFFICER"),
  validate({ body: createAnnouncementBodySchema }),
  create
);

/**
 * @deprecated Use POST /api/announcements/school or /api/announcements/moe.
 * Kept for backward compatibility until the frontend adopts the split routes.
 * @openapi
 * /api/announcements:
 *   post:
 *     tags: [Announcements]
 *     summary: (Deprecated) Publish an announcement
 *     deprecated: true
 *     security: [{ bearerAuth: [] }]
 */
router.post(
  "/",
  authenticate,
  authorizeRoles("MOE_OFFICER", "SCHOOL_ADMIN"),
  validate({ body: createAnnouncementBodySchema }),
  create
);

/**
 * @openapi
 * /api/announcements/{id}:
 *   put:
 *     tags: [Announcements]
 *     summary: Update an announcement (owner only)
 *     security: [{ bearerAuth: [] }]
 */
router.put(
  "/:id",
  authenticate,
  authorizeRoles("MOE_OFFICER", "SCHOOL_ADMIN"),
  validate({ params: idParamsSchema, body: updateAnnouncementBodySchema }),
  update
);

/**
 * @openapi
 * /api/announcements/{id}:
 *   delete:
 *     tags: [Announcements]
 *     summary: Delete an announcement (owner only)
 *     security: [{ bearerAuth: [] }]
 */
router.delete(
  "/:id",
  authenticate,
  authorizeRoles("MOE_OFFICER", "SCHOOL_ADMIN"),
  validate({ params: idParamsSchema }),
  remove
);

export default router;
