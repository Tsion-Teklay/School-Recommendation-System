import express from "express";
import { recommend } from "../controllers/recommendation.controller.js";
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
 *       Phase 0 uses the same mock ranking as before; Phase 6 will replace this
 *       with a content-based v1 recommender (curriculum, budget, distance,
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
  recommend
);

export default router;
