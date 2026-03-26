import express from "express";
import * as controller from "../controllers/notification.controller.js";
import { authenticate } from "../middlewares/auth.middleware.js";

const router = express.Router();

router.get("/", authenticate, controller.getMy);
router.put("/:id/read", authenticate, controller.markRead);

export default router;