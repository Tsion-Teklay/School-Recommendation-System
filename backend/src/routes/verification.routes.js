import express from "express";

import { authenticate } from "../middlewares/auth.middleware.js";
import { authorizeRoles } from "../middlewares/role.middleware.js";
import { validate } from "../middlewares/validate.middleware.js";
import { verificationDocumentsUpload } from "../config/uploads.js";
import {
  idParamsSchema,
  schoolIdParamsSchema,
} from "../schemas/common.schema.js";
import {
  listVerificationQuerySchema,
  reviewVerificationBodySchema,
  submitVerificationBodySchema,
} from "../schemas/verification.schema.js";
import {
  submit,
  list,
  getOne,
  review,
} from "../controllers/verification.controller.js";

const router = express.Router();

/**
 * @openapi
 * /api/schools/{schoolId}/verification-requests:
 *   post:
 *     tags: [Verification]
 *     summary: Submit a verification request for a school (SCHOOL_ADMIN only, owner)
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               documents:
 *                 type: array
 *                 items: { type: string, format: binary }
 *               notes:
 *                 type: string
 *     responses:
 *       201: { description: Submitted }
 *       400: { description: Validation error / no documents / unsupported MIME }
 *       403: { description: Not the school owner }
 *       409: { description: A pending request already exists for this school }
 */
router.post(
  "/schools/:schoolId/verification-requests",
  authenticate,
  authorizeRoles("SCHOOL_ADMIN"),
  validate({ params: schoolIdParamsSchema }),
  verificationDocumentsUpload,
  validate({ body: submitVerificationBodySchema }),
  submit
);

/**
 * @openapi
 * /api/verification-requests:
 *   get:
 *     tags: [Verification]
 *     summary: List verification requests
 *     description: |
 *       MOE_OFFICER sees every request; SCHOOL_ADMIN sees only requests for
 *       schools they own.
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: status
 *         schema: { type: string, enum: [PENDING, APPROVED, REJECTED] }
 *       - in: query
 *         name: schoolId
 *         schema: { type: integer }
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 10 }
 */
router.get(
  "/verification-requests",
  authenticate,
  authorizeRoles("MOE_OFFICER", "SCHOOL_ADMIN"),
  validate({ query: listVerificationQuerySchema }),
  list
);

/**
 * @openapi
 * /api/verification-requests/{id}:
 *   get:
 *     tags: [Verification]
 *     summary: Fetch a single verification request
 *     security: [{ bearerAuth: [] }]
 */
router.get(
  "/verification-requests/:id",
  authenticate,
  authorizeRoles("MOE_OFFICER", "SCHOOL_ADMIN"),
  validate({ params: idParamsSchema }),
  getOne
);

/**
 * @openapi
 * /api/verification-requests/{id}/review:
 *   post:
 *     tags: [Verification]
 *     summary: Approve or reject a verification request (MOE_OFFICER only)
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [status]
 *             properties:
 *               status: { type: string, enum: [APPROVED, REJECTED] }
 *               reviewNotes: { type: string }
 */
router.post(
  "/verification-requests/:id/review",
  authenticate,
  authorizeRoles("MOE_OFFICER"),
  validate({ params: idParamsSchema, body: reviewVerificationBodySchema }),
  review
);

export default router;
