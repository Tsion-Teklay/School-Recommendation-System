import { asyncHandler } from "../middlewares/async.middleware.js";  
import * as demographicsService from "../services/demographics.service.js";  
  
export const create = asyncHandler(async (req, res) => {  
  const result = await demographicsService.createDemographics(req.body, req.user.id);  
  res.status(201).json(result);  
});  
  
export const getBySchool = asyncHandler(async (req, res) => {  
  const { schoolId } = req.params;  
  const result = await demographicsService.getSchoolDemographics(Number(schoolId));  
  res.json(result);  
});  
  
export const getByYear = asyncHandler(async (req, res) => {  
  const { schoolId, academicYear } = req.params;  
  const result = await demographicsService.getDemographicsByYear(Number(schoolId), Number(academicYear));  
  res.json(result);  
});  
  
export const update = asyncHandler(async (req, res) => {  
  const { id } = req.params;  
  const result = await demographicsService.updateDemographics(Number(id), req.body, req.user.id);  
  res.json(result);  
});  
  
export const remove = asyncHandler(async (req, res) => {  
  const { id } = req.params;  
  const result = await demographicsService.deleteDemographics(Number(id), req.user.id);  
  res.json(result);  
});