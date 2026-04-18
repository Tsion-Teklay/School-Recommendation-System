import express from "express";
import {
  create,
  getAll,
  getOne,
  update,
  remove,
} from "../controllers/school.controller.js";
import { authenticate } from "../middlewares/auth.middleware.js";
import { authorizeRoles } from "../middlewares/role.middleware.js";
import { validate } from "../middlewares/validate.middleware.js";
import { idParamsSchema } from "../schemas/common.schema.js";
import {
  createSchoolBodySchema,
  updateSchoolBodySchema,
  listSchoolsQuerySchema,
} from "../schemas/school.schema.js";

const router = express.Router();

/**
 * @openapi
 * /api/schools:
 *   get:
 *     tags: [Schools]
 *     summary: List schools (public) with search, filter, pagination
 *     parameters:
 *       - in: query
 *         name: search
 *         schema: { type: string }
 *       - in: query
 *         name: curriculum
 *         schema: { type: string, enum: [LOCAL, INTERNATIONAL] }
 *       - in: query
 *         name: minFee
 *         schema: { type: number }
 *       - in: query
 *         name: maxFee
 *         schema: { type: number }
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 10 }
 *     responses:
 *       200: { description: Paginated list of schools }
 */
router.get("/", validate({ query: listSchoolsQuerySchema }), getAll);

/**
 * @openapi
 * /api/schools/{id}:
 *   get:
 *     tags: [Schools]
 *     summary: Get a school by id (public)
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200: { description: School }
 *       404: { description: School not found }
 */
router.get("/:id", validate({ params: idParamsSchema }), getOne);

/**
 * @openapi
 * /api/schools:
 *   post:
 *     tags: [Schools]
 *     summary: Create a school (SCHOOL_ADMIN only)
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       201: { description: School created }
 *       401: { description: Unauthenticated }
 *       403: { description: Forbidden }
 */
router.post(
  "/",
  authenticate,
  authorizeRoles("SCHOOL_ADMIN"),
  validate({ body: createSchoolBodySchema }),
  create
);

/**
 * @openapi
 * /api/schools/{id}:
 *   put:
 *     tags: [Schools]
 *     summary: Update own school (SCHOOL_ADMIN only)
 *     security: [{ bearerAuth: [] }]
 */
router.put(
  "/:id",
  authenticate,
  authorizeRoles("SCHOOL_ADMIN"),
  validate({ params: idParamsSchema, body: updateSchoolBodySchema }),
  update
);

/**
 * @openapi
 * /api/schools/{id}:
 *   delete:
 *     tags: [Schools]
 *     summary: Delete own school (SCHOOL_ADMIN only)
 *     security: [{ bearerAuth: [] }]
 */
router.delete(
  "/:id",
  authenticate,
  authorizeRoles("SCHOOL_ADMIN"),
  validate({ params: idParamsSchema }),
  remove
);

export default router;
