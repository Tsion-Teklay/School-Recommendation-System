import { asyncHandler } from "../middlewares/async.middleware.js";
import {
  createSchool,
  getAllSchools,
  getSchoolById,
  updateSchool,
  deleteSchool,
  revokeVerification,
} from "../services/school.service.js";

export const create = asyncHandler(async (req, res) => {
  const school = await createSchool(req.body, req.user.id);
  res.status(201).json({
    message: "School created successfully",
    school,
  });
});

export const getAll = asyncHandler(async (req, res) => {  
  const query = { ...req.query };  
    
  // If user is an admin, force the filter to their own ID  
  if (req.user?.role === 'SCHOOL_ADMIN') {  
    query.adminId = req.user.id;  
  }  
  
  const result = await getAllSchools(query);  
  res.json({  
    message: "Schools fetched successfully",  
    ...result,  
  });  
});

export const getOne = asyncHandler(async (req, res) => {
  const school = await getSchoolById(req.params.id);
  res.json({
    message: "School fetched successfully",
    school,
  });
});

export const update = asyncHandler(async (req, res) => {
  const school = await updateSchool(req.params.id, req.body, req.user.id);
  res.json({
    message: "School updated successfully",
    school,
  });
});

export const remove = asyncHandler(async (req, res) => {
  const result = await deleteSchool(req.params.id, req.user.id);
  res.json(result);
});


export const revoke = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { reason } = req.body;
  const school = await revokeVerification(Number(id), req.user.id, reason);
  res.status(200).json({ school });
});