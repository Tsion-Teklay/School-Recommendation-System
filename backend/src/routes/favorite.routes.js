import express from "express";
import { authenticate } from "../middlewares/auth.middleware.js";
import { authorizeRoles } from "../middlewares/role.middleware.js";
import { validate } from "../middlewares/validate.middleware.js";
import { schoolIdParamsSchema } from "../schemas/common.schema.js";
import {
  add,
  getMine,
  remove,
} from "../controllers/favorite.controller.js";

const router = express.Router();

/**
 * @openapi
 * /api/favorites/{schoolId}:
 *   post:
 *     tags: [Favorites]
 *     summary: Add a school to favorites (PARENT only)
 *     security: [{ bearerAuth: [] }]
 */
router.post(
  "/:schoolId",
  authenticate,
  authorizeRoles("PARENT"),
  validate({ params: schoolIdParamsSchema }),
  add
);

/**
 * @openapi
 * /api/favorites:
 *   get:
 *     tags: [Favorites]
 *     summary: List my favorites (PARENT only)
 *     security: [{ bearerAuth: [] }]
 */
router.get("/", authenticate, authorizeRoles("PARENT"), getMine);

/**
 * @openapi
 * /api/favorites/{schoolId}:
 *   delete:
 *     tags: [Favorites]
 *     summary: Remove a school from favorites (PARENT only)
 *     security: [{ bearerAuth: [] }]
 */
router.delete(
  "/:schoolId",
  authenticate,
  authorizeRoles("PARENT"),
  validate({ params: schoolIdParamsSchema }),
  remove
);

export default router;
