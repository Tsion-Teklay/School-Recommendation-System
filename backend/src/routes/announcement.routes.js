import express from "express";
import * as controller from "../controllers/announcement.controller.js";
import { authenticate } from "../middlewares/auth.middleware.js";
import { authorizeRoles } from "../middlewares/role.middleware.js";

const router = express.Router();

// ✅ PUBLIC
router.get("/", controller.getAll);
router.get("/:id", controller.getOne);

// ✅ PROTECTED
router.post(
  "/",
  authenticate,
  authorizeRoles("MOE_OFFICER", "SCHOOL_ADMIN"),
  controller.create
);

router.put(
  "/:id",
  authenticate,
  authorizeRoles("MOE_OFFICER", "SCHOOL_ADMIN"),
  controller.update
);

router.delete(
  "/:id",
  authenticate,
  authorizeRoles("MOE_OFFICER", "SCHOOL_ADMIN"),
  controller.remove
);

export default router;