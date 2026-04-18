import express from "express";
import { register, login } from "../controllers/auth.controller.js";
import { validate } from "../middlewares/validate.middleware.js";
import {
  registerBodySchema,
  loginBodySchema,
} from "../schemas/auth.schema.js";

const router = express.Router();

/**
 * @openapi
 * /api/auth/register:
 *   post:
 *     tags: [Auth]
 *     summary: Register a new user
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [fullName, email, password, role]
 *             properties:
 *               fullName: { type: string }
 *               email: { type: string, format: email }
 *               phone: { type: string }
 *               password: { type: string, minLength: 6 }
 *               role:
 *                 type: string
 *                 enum: [PARENT, SCHOOL_ADMIN, MOE_OFFICER, MODERATOR]
 *     responses:
 *       201: { description: User created }
 *       400: { description: Validation error }
 *       409: { description: Email already registered }
 */
router.post("/register", validate({ body: registerBodySchema }), register);

/**
 * @openapi
 * /api/auth/login:
 *   post:
 *     tags: [Auth]
 *     summary: Log in and receive a JWT
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email, password]
 *             properties:
 *               email: { type: string, format: email }
 *               password: { type: string }
 *     responses:
 *       200: { description: JWT issued }
 *       401: { description: Invalid credentials or account deactivated }
 */
router.post("/login", validate({ body: loginBodySchema }), login);

export default router;
