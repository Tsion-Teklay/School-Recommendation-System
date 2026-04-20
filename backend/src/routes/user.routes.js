import express from "express";
import {
  me,
  updateMeHandler,
  deactivateMeHandler,
} from "../controllers/user.controller.js";
import { authenticate } from "../middlewares/auth.middleware.js";
import { validate } from "../middlewares/validate.middleware.js";
import { updateMeBodySchema } from "../schemas/user.schema.js";

const router = express.Router();

/**
 * @openapi
 * /api/users/me:
 *   get:
 *     tags: [Users]
 *     summary: Get the current user's profile
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: Current user }
 *       401: { description: Missing or invalid JWT }
 */
router.get("/me", authenticate, me);

/**
 * @openapi
 * /api/users/me:
 *   put:
 *     tags: [Users]
 *     summary: Update the current user's profile
 *     description: Only fullName and phone can be changed here. Email/role/status changes go through dedicated flows.
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               fullName: { type: string }
 *               phone: { type: string }
 *     responses:
 *       200: { description: Profile updated }
 */
router.put(
  "/me",
  authenticate,
  validate({ body: updateMeBodySchema }),
  updateMeHandler
);

/**
 * @openapi
 * /api/users/me/deactivate:
 *   post:
 *     tags: [Users]
 *     summary: Self-deactivate the current user
 *     description: Sets accountStatus to DEACTIVATED. Further logins will fail until an admin reactivates the account.
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: Account deactivated }
 */
router.post("/me/deactivate", authenticate, deactivateMeHandler);

export default router;
