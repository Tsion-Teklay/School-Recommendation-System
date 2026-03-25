import express from "express";
import { authenticate } from "../middlewares/auth.middleware.js";
import { authorizeRoles } from "../middlewares/role.middleware.js";
import {
  create,
  getBySchool,
  update,
  remove,
} from "../controllers/review.controller.js";

const router = express.Router();

// Create review (PARENT only)
router.post(
  "/:schoolId",
  authenticate,
  authorizeRoles("PARENT"),
  create
);

// Public
router.get("/school/:schoolId", getBySchool);

// Update
router.put(
  "/:id",
  authenticate,
  authorizeRoles("PARENT"),
  update
);

// Delete
router.delete(
  "/:id",
  authenticate,
  authorizeRoles("PARENT"),
  remove
);

export default router;