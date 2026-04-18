import { asyncHandler } from "../middlewares/async.middleware.js";
import {
  createSchool,
  getAllSchools,
  getSchoolById,
  updateSchool,
  deleteSchool,
} from "../services/school.service.js";

export const create = asyncHandler(async (req, res) => {
  const school = await createSchool(req.body, req.user.id);
  res.status(201).json({
    message: "School created successfully",
    school,
  });
});

export const getAll = asyncHandler(async (req, res) => {
  const result = await getAllSchools(req.query);
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
