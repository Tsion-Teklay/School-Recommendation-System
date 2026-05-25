import express from "express";
import { authenticate } from "../middlewares/auth.middleware.js";
import { authorizeRoles } from "../middlewares/role.middleware.js";
import { validate } from "../middlewares/validate.middleware.js";
import { schoolIdParamsSchema, idParamsSchema } from "../schemas/common.schema.js";
import {
  createDemographicsBodySchema,
  updateDemographicsBodySchema,
} from "../schemas/demographics.schema.js";
import * as controller from "../controllers/demographics.controller.js";

const router = express.Router();

router.post(
  "/",
  authenticate,
  authorizeRoles("SCHOOL_ADMIN"),
  validate({ body: createDemographicsBodySchema }),
  controller.create
);

router.get(
  "/school/:schoolId",
  validate({ params: schoolIdParamsSchema }),
  controller.getBySchool
);

router.get(
  "/school/:schoolId/year/:academicYear",
  validate({ params: schoolIdParamsSchema }),
  controller.getByYear
);

router.put(
  "/:id",
  authenticate,
  authorizeRoles("SCHOOL_ADMIN"),
  validate({ params: idParamsSchema, body: updateDemographicsBodySchema }),
  controller.update
);

router.delete(
  "/:id",
  authenticate,
  authorizeRoles("SCHOOL_ADMIN"),
  validate({ params: idParamsSchema }),
  controller.remove
);

export default router;