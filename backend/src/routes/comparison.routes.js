import express from "express";
import { authenticate } from "../middlewares/auth.middleware.js";
import { authorizeRoles } from "../middlewares/role.middleware.js";
import { validate } from "../middlewares/validate.middleware.js";
import { idParamsSchema } from "../schemas/common.schema.js";
import {
  createComparisonBodySchema,
  listComparisonsQuerySchema,
} from "../schemas/comparison.schema.js";
import {
  create,
  getMine,
  getOne,
  remove,
} from "../controllers/comparison.controller.js";

const router = express.Router();

/**
 * @openapi
 * /api/comparisons:
 *   post:
 *     tags: [Comparisons]
 *     summary: Create a side-by-side comparison of 2–5 schools (PARENT only)
 *     security: [{ bearerAuth: [] }]
 */
router.post(
  "/",
  authenticate,
  authorizeRoles("PARENT"),
  validate({ body: createComparisonBodySchema }),
  create
);

/**
 * @openapi
 * /api/comparisons:
 *   get:
 *     tags: [Comparisons]
 *     summary: List my saved comparisons (PARENT only)
 *     security: [{ bearerAuth: [] }]
 */
router.get(
  "/",
  authenticate,
  authorizeRoles("PARENT"),
  validate({ query: listComparisonsQuerySchema }),
  getMine
);

/**
 * @openapi
 * /api/comparisons/{id}:
 *   get:
 *     tags: [Comparisons]
 *     summary: Fetch a saved comparison (owner only)
 *     security: [{ bearerAuth: [] }]
 */
router.get(
  "/:id",
  authenticate,
  authorizeRoles("PARENT"),
  validate({ params: idParamsSchema }),
  getOne
);

/**
 * @openapi
 * /api/comparisons/{id}:
 *   delete:
 *     tags: [Comparisons]
 *     summary: Delete a saved comparison (owner only)
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
