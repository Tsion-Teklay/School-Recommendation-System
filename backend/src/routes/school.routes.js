import express from "express";
import {
  create,
  getAll,
  getOne,
  update,
  remove
} from "../controllers/school.controller.js";

import { authenticate } from "../middlewares/auth.middleware.js";
import { authorizeRoles } from "../middlewares/role.middleware.js";

const router = express.Router();

// 🔓 PUBLIC
router.get("/", getAll);
router.get("/:id", getOne);

// 🔐 ONLY SCHOOL_ADMIN
router.post(
  "/",
  authenticate,
  authorizeRoles("SCHOOL_ADMIN"),
  create
);

// 🔐 ONLY SCHOOL_ADMIN
router.put(
  "/:id",
  authenticate,
  authorizeRoles("SCHOOL_ADMIN"),
  update
);
router.delete(
  "/:id",
  authenticate,
  authorizeRoles("SCHOOL_ADMIN"),
  remove
);

export default router;