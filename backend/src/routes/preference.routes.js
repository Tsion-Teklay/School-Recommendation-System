import express from "express";
import {
  savePreference,
  getMy,
} from "../controllers/preference.controller.js";
import { authenticate } from "../middlewares/auth.middleware.js";
import { authorizeRoles } from "../middlewares/role.middleware.js";

const router = express.Router();

// Only parents
router.post(
  "/",
  authenticate,
  authorizeRoles("PARENT"),
  savePreference
);

router.get(
  "/me",
  authenticate,
  authorizeRoles("PARENT"),
  getMy
);

export default router;