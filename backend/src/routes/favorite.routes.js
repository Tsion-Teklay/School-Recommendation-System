import express from "express";
import { authenticate } from "../middlewares/auth.middleware.js";
import { authorizeRoles } from "../middlewares/role.middleware.js";
import {
  add,
  getMine,
  remove,
} from "../controllers/favorite.controller.js";

const router = express.Router();

// Only PARENT can use favorites
router.post(
  "/:schoolId",
  authenticate,
  authorizeRoles("PARENT"),
  add
);

router.get(
  "/",
  authenticate,
  authorizeRoles("PARENT"),
  getMine
);

router.delete(
  "/:schoolId",
  authenticate,
  authorizeRoles("PARENT"),
  remove
);

export default router;