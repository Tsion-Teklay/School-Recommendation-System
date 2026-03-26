import express from "express";
import * as controller from "../controllers/analytics.controller.js";
import { authenticate } from "../middlewares/auth.middleware.js";
import { authorizeRoles } from "../middlewares/role.middleware.js";

const router = express.Router();

// PUBLIC
router.get("/school/:id", controller.getSchool);

// PROTECTED
router.post(
  "/",
  authenticate,
  authorizeRoles("MOE_OFFICER", "SCHOOL_ADMIN"),
  controller.create
);

router.get(
  "/dashboard",
  authenticate,
  authorizeRoles("MOE_OFFICER", "MODERATOR"),
  controller.dashboard
);

export default router;