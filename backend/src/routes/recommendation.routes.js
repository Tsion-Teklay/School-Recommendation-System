import express from "express";
import { recommend } from "../controllers/recommendation.controller.js";

const router = express.Router();

// Public for now
router.get("/", recommend);

export default router;