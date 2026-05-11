import express from "express";
import { authenticate } from "../middlewares/auth.middleware.js";
import { authorizeRoles } from "../middlewares/role.middleware.js";
import { validate } from "../middlewares/validate.middleware.js";
import {
  idParamsSchema,
  schoolIdParamsSchema,
} from "../schemas/common.schema.js";
import {
  createReviewBodySchema,
  updateReviewBodySchema,
} from "../schemas/review.schema.js";
import {
  create,
  getBySchool,
  update,
  remove,
} from "../controllers/review.controller.js";

const router = express.Router();

/**
 * @openapi
 * /api/reviews/{schoolId}:
 *   post:
 *     tags: [Reviews]
 *     summary: Create a review for a school (PARENT only)
 *     security: [{ bearerAuth: [] }]
 */
router.post(
  "/:schoolId",
  authenticate,
  authorizeRoles("PARENT"),
  validate({ params: schoolIdParamsSchema, body: createReviewBodySchema }),
  create
);

/**
 * @openapi
 * /api/reviews/school/{schoolId}:
 *   get:
 *     tags: [Reviews]
 *     summary: Get reviews for a school (public)
 */
router.get(
  "/school/:schoolId",
  validate({ params: schoolIdParamsSchema }),
  getBySchool
);

/**
 * @openapi
 * /api/reviews/{id}:
 *   put:
 *     tags: [Reviews]
 *     summary: Update own review (PARENT only)
 *     security: [{ bearerAuth: [] }]
 */
router.put(
  "/:id",
  authenticate,
  authorizeRoles("PARENT"),
  validate({ params: idParamsSchema, body: updateReviewBodySchema }),
  update
);

/**
 * @openapi
 * /api/reviews/{id}:
 *   delete:
 *     tags: [Reviews]
 *     summary: Delete own review (PARENT only)
 *     security: [{ bearerAuth: [] }]
 */
router.delete(
  "/:id",
  authenticate,
  authorizeRoles("PARENT"),
  validate({ params: idParamsSchema }),
  remove
);

export default router;
