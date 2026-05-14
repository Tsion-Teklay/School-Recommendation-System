import express from "express";  
import { authenticate } from "../middlewares/auth.middleware.js";  
import { validate } from "../middlewares/validate.middleware.js";  
import { z } from "zod";  
import {  
  toggleLikeHandler,  
  getLikeCountHandler,  
  getUserLikeStatusHandler,  
} from "../controllers/like.controller.js";  
  
const router = express.Router();  
  
const toggleLikeSchema = z.object({  
  targetType: z.enum(["ANNOUNCEMENT", "FORUM_POST"]),  
  targetId: z.coerce.number(),  
});  
  
// POST /api/likes/toggle - Toggle like on announcement or forum post  
router.post(  
  "/toggle",  
  authenticate,  
  validate({ body: toggleLikeSchema }),  
  toggleLikeHandler  
);  
  
// GET /api/likes/:targetType/:targetId/count - Get like count  
router.get("/:targetType/:targetId/count", getLikeCountHandler);  
  
// GET /api/likes/:targetType/:targetId/status - Get current user's like status  
router.get(  
  "/:targetType/:targetId/status",  
  authenticate,  
  getUserLikeStatusHandler  
);  
  
export default router;