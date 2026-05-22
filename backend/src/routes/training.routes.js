import express from "express";

import {
  getTrainingData
} from "../controllers/training.controller.js";

const router = express.Router();

router.get(
  "/",
  getTrainingData
);

export default router;