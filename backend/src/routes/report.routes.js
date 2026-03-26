import express from "express";
import * as controller from "../controllers/report.controller.js";
import { authenticate } from "../middlewares/auth.middleware.js";
import { authorizeRoles } from "../middlewares/role.middleware.js";

const router = express.Router();

// ✅ Create report (ANY authenticated user)
router.post("/", authenticate, controller.create);

// ✅ Moderator only
router.get("/", authenticate, authorizeRoles("MODERATOR"), controller.getAll);

router.get(
  "/:id",
  authenticate,
  authorizeRoles("MODERATOR"),
  controller.getOne
);

router.post(
  "/:id/action",
  authenticate,
  authorizeRoles("MODERATOR"),
  controller.action
);

export default router;