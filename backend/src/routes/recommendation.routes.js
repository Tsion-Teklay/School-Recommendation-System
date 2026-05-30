import express from "express";
import { z } from "zod"; // Ensure z is imported for validation schemas
import {
  recommend,
  feedback,
  updateInteractionResult,
} from "../controllers/recommendation.controller.js";
import { authenticate } from "../middlewares/auth.middleware.js";
import { authorizeRoles } from "../middlewares/role.middleware.js";
import { validate } from "../middlewares/validate.middleware.js";
import { recommendationsQuerySchema } from "../schemas/recommendation.schema.js";

const router = express.Router();

/**
 * @openapi
 * /api/recommendations:
 *   get:
 *     tags: [Recommendations]
 *     summary: Get ranked school recommendations (PARENT only)
 *     description: |
 *       Content-based recommender (curriculum, budget, distance,
 *       rating, facilities, verification bonus).
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: curriculum
 *         schema: { type: string, enum: [LOCAL, INTERNATIONAL] }
 *       - in: query
 *         name: maxFee
 *         schema: { type: number }
 *     responses:
 *       200: { description: Ranked schools }
 *       401: { description: Unauthenticated }
 *       403: { description: Not a parent }
 */
router.get(
  "/",
  authenticate,
  authorizeRoles("PARENT"),
  validate({ query: recommendationsQuerySchema }),
  recommend,
);

router.post("/:id/feedback", authenticate, authorizeRoles("PARENT"), feedback);

router.put(
  "/:recommendationId/schools/:schoolId/interaction",
  authenticate,
  authorizeRoles("PARENT"),
  validate({
    params: z.object({
      recommendationId: z.string().transform(Number),
      schoolId: z.string().transform(Number),
    }),
    body: z.object({
      result: z.enum(["OPENED", "FOLLOWED", "IGNORED"]),
    }),
  }),
  updateInteractionResult,
);

export default router;
