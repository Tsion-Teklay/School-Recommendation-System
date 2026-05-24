import { asyncHandler } from "../middlewares/async.middleware.js";  
import * as achievementService from "../services/achievement.service.js";  
  
// Achievement controllers  
export const createAchievement = asyncHandler(async (req, res) => {  
  const result = await achievementService.createAchievement(req.body, req.user.id);  
  res.status(201).json(result);  
});  
  
export const getSchoolAchievements = asyncHandler(async (req, res) => {  
  const { schoolId } = req.params;  
  const result = await achievementService.getSchoolAchievements(Number(schoolId));  
  res.json(result);  
});  
  
export const getPendingAchievements = asyncHandler(async (req, res) => {  
  const result = await achievementService.getPendingAchievements();  
  res.json(result);  
});  
  
export const reviewAchievement = asyncHandler(async (req, res) => {  
  const { id } = req.params;  
  const result = await achievementService.reviewAchievement(Number(id), req.body, req.user.id);  
  res.json(result);  
});  
  
export const deleteAchievement = asyncHandler(async (req, res) => {  
  const { id } = req.params;  
  const result = await achievementService.deleteAchievement(Number(id), req.user.id);  
  res.json(result);  
});  
  
// Staff breakdown controllers  
export const createStaffBreakdown = asyncHandler(async (req, res) => {  
  const result = await achievementService.createStaffBreakdown(req.body, req.user.id);  
  res.status(201).json(result);  
});  
  
export const getSchoolStaffBreakdown = asyncHandler(async (req, res) => {  
  const { schoolId } = req.params;  
  const result = await achievementService.getSchoolStaffBreakdown(Number(schoolId));  
  res.json(result);  
});  
  
export const updateStaffBreakdown = asyncHandler(async (req, res) => {  
  const { id } = req.params;  
  const result = await achievementService.updateStaffBreakdown(Number(id), req.body, req.user.id);  
  res.json(result);  
});  
  
export const deleteStaffBreakdown = asyncHandler(async (req, res) => {  
  const { id } = req.params;  
  const result = await achievementService.deleteStaffBreakdown(Number(id), req.user.id);  
  res.json(result);  
});