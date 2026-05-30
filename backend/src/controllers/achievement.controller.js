import { asyncHandler } from "../middlewares/async.middleware.js";
import { relativeUrl } from "../config/uploads.js";
import * as achievementService from "../services/achievement.service.js";  
  
// Achievement controllers
export const createAchievement = asyncHandler(async (req, res) => {
  // multer populates req.files; map to public URLs before persisting.
  const documents = (req.files || []).map((f) => ({
    url: relativeUrl(f),
    originalName: f.originalname,
    size: f.size,
    mimeType: f.mimetype,
  }));

  const result = await achievementService.createAchievement({
    schoolId: req.params.schoolId,
    title: req.query.title,
    description: req.body.description,
    year: req.query.year,
    documents,
  }, req.user.id);  
  res.status(201).json(result);  
});  
  
export const getSchoolAchievements = asyncHandler(async (req, res) => {  
  const { schoolId } = req.params;  
  const result = await achievementService.getSchoolAchievements(Number(schoolId));  
  res.json(result);  
});  
  
export const getPendingAchievements = asyncHandler(async (req, res) => {
  const result = await achievementService.getPendingAchievements(req.user);
  res.json(result);
});

export const getAchievementsByStatus = asyncHandler(async (req, res) => {
  const { status } = req.query;
  const result = await achievementService.getAchievementsByStatus(status, req.user);
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