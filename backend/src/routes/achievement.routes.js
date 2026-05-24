import { Router } from "express";  
import { authenticate } from "../middlewares/auth.middleware.js";  
import { authorizeRoles } from "../middlewares/role.middleware.js";
import { validate } from "../middlewares/validate.middleware.js";  
import * as achievementController from "../controllers/achievement.controller.js";  
import * as achievementSchemas from "../schemas/achievement.schema.js";  
  
const router = Router();  
  
// Achievement routes  
router.post(  
  "/achievements",  
  authenticate,  
  authorizeRoles("SCHOOL_ADMIN"),  
  validate({ body: achievementSchemas.createAchievementBodySchema }),  
  achievementController.createAchievement  
);  
  
router.get(  
  "/achievements/school/:schoolId",  
  authenticate,  
  achievementController.getSchoolAchievements  
);  
  
router.get(  
  "/achievements/pending",  
  authenticate,  
  authorizeRoles("MOE_OFFICER"),  
  achievementController.getPendingAchievements  
);  
  
router.post(  
  "/achievements/:id/review",  
  authenticate,  
  authorizeRoles("MOE_OFFICER"),  
  validate({ body: achievementSchemas.reviewAchievementBodySchema }),  
  achievementController.reviewAchievement  
);  
  
router.delete(  
  "/achievements/:id",  
  authenticate,  
  authorizeRoles("SCHOOL_ADMIN"),  
  achievementController.deleteAchievement  
);  
  
// Staff breakdown routes  
router.post(  
  "/staff-breakdown",  
  authenticate,  
  authorizeRoles("SCHOOL_ADMIN"),  
  validate({ body: achievementSchemas.createStaffBreakdownBodySchema }),  
  achievementController.createStaffBreakdown  
);  
  
router.get(  
  "/staff-breakdown/school/:schoolId",  
  authenticate,  
  achievementController.getSchoolStaffBreakdown  
);  
  
router.put(  
  "/staff-breakdown/:id",  
  authenticate,  
  authorizeRoles("SCHOOL_ADMIN"),  
  validate({ body: achievementSchemas.updateStaffBreakdownBodySchema }),  
  achievementController.updateStaffBreakdown  
);  
  
router.delete(  
  "/staff-breakdown/:id",  
  authenticate,  
  authorizeRoles("SCHOOL_ADMIN"),  
  achievementController.deleteStaffBreakdown  
);  
  
export default router;