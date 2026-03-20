import express from "express";
import { authenticate } from "../middlewares/auth.middleware.js";
import { authorizeRoles } from "../middlewares/role.middleware.js";
import {
  createTestResource,
  getTestResources,
} from "../controllers/test.controller.js";

const router = express.Router();

// Only SCHOOL_ADMIN can create
router.post(
  "/",
  authenticate,
  authorizeRoles("SCHOOL_ADMIN"),
  createTestResource
);

// PARENT, MODERATOR, MOE_OFFICER can view
router.get(
  "/all",
  authenticate,
  authorizeRoles("PARENT", "MODERATOR", "MOE_OFFICER"),
  getTestResources
);

export default router;