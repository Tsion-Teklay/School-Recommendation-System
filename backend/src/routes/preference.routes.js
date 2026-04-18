import express from "express";
import {
  savePreference,
  getMy,
} from "../controllers/preference.controller.js";
import { authenticate } from "../middlewares/auth.middleware.js";
import { authorizeRoles } from "../middlewares/role.middleware.js";
import { validate } from "../middlewares/validate.middleware.js";
import { upsertPreferenceBodySchema } from "../schemas/preference.schema.js";

const router = express.Router();

/**
 * @openapi
 * /api/preferences:
 *   post:
 *     tags: [Preferences]
 *     summary: Upsert preferences (PARENT only)
 *     security: [{ bearerAuth: [] }]
 */
router.post(
  "/",
  authenticate,
  authorizeRoles("PARENT"),
  validate({ body: upsertPreferenceBodySchema }),
  savePreference
);

/**
 * @openapi
 * /api/preferences/me:
 *   get:
 *     tags: [Preferences]
 *     summary: Get my preferences (PARENT only)
 *     security: [{ bearerAuth: [] }]
 */
router.get("/me", authenticate, authorizeRoles("PARENT"), getMy);

export default router;
