import express from "express";
import * as controller from "../controllers/notification.controller.js";
import { authenticate } from "../middlewares/auth.middleware.js";
import { validate } from "../middlewares/validate.middleware.js";
import { idParamsSchema } from "../schemas/common.schema.js";
import { listNotificationsQuerySchema } from "../schemas/notification.schema.js";

const router = express.Router();

/**
 * @openapi
 * /api/notifications:
 *   get:
 *     tags: [Notifications]
 *     summary: List my notifications (any authenticated user)
 *     security: [{ bearerAuth: [] }]
 */
router.get(
  "/",
  authenticate,
  validate({ query: listNotificationsQuerySchema }),
  controller.getMy
);

/**
 * @openapi
 * /api/notifications/{id}/read:
 *   put:
 *     tags: [Notifications]
 *     summary: Mark a notification as read (owner only)
 *     security: [{ bearerAuth: [] }]
 */
router.put(
  "/:id/read",
  authenticate,
  validate({ params: idParamsSchema }),
  controller.markRead
);

export default router;
