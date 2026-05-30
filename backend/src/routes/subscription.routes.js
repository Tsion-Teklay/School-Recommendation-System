import express from "express";
import { authenticate } from "../middlewares/auth.middleware.js";
import { authorizeRoles } from "../middlewares/role.middleware.js";
import { validate } from "../middlewares/validate.middleware.js";
import { schoolIdParamsSchema } from "../schemas/common.schema.js";
import { listFollowsQuerySchema } from "../schemas/subscription.schema.js";
import {
  follow,
  unfollow,
  getMine,
} from "../controllers/subscription.controller.js";

/**
 * Follow/subscribe routes.
 *
 * Mounted under two paths in app.js so the URL structure matches the
 * conceptual model:
 *   - POST/DELETE /api/schools/:schoolId/follow    (action on a school)
 *   - GET         /api/me/follows                  (action on me)
 */

export const schoolFollowRouter = express.Router({ mergeParams: true });

/**
 * @openapi
 * /api/schools/{schoolId}/follow:
 *   post:
 *     tags: [Subscriptions]
 *     summary: Follow a school (PARENT only)
 *     security: [{ bearerAuth: [] }]
 */
schoolFollowRouter.post(
  "/",
  authenticate,
  authorizeRoles("PARENT"),
  validate({ params: schoolIdParamsSchema }),
  follow
);

/**
 * @openapi
 * /api/schools/{schoolId}/follow:
 *   delete:
 *     tags: [Subscriptions]
 *     summary: Unfollow a school (PARENT only)
 *     security: [{ bearerAuth: [] }]
 */
schoolFollowRouter.delete(
  "/",
  authenticate,
  authorizeRoles("PARENT"),
  validate({ params: schoolIdParamsSchema }),
  unfollow
);

export const myFollowsRouter = express.Router();

/**
 * @openapi
 * /api/me/follows:
 *   get:
 *     tags: [Subscriptions]
 *     summary: List schools I follow (PARENT only)
 *     security: [{ bearerAuth: [] }]
 */
myFollowsRouter.get(
  "/",
  authenticate,
  authorizeRoles("PARENT"),
  validate({ query: listFollowsQuerySchema }),
  getMine
);
