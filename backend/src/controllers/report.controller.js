import { asyncHandler } from "../middlewares/async.middleware.js";
import {
  createReport,
  getAllReports,
  getReportById,
  takeAction,
  getReportedContent as getReportedContentService,
} from "../services/report.service.js";

export const create = asyncHandler(async (req, res) => {
  const report = await createReport(req.body, req.user.id);
  res.status(201).json({
    message: "Report submitted successfully",
    report,
  });
});

export const getAll = asyncHandler(async (req, res) => {
  const reports = await getAllReports(req.query);
  res.json({
    message: "Reports fetched successfully",
    data: reports,
  });
});

export const getOne = asyncHandler(async (req, res) => {
  const report = await getReportById(req.params.id);
  res.json({
    message: "Report fetched successfully",
    report,
  });
});

export const action = asyncHandler(async (req, res) => {
  const result = await takeAction(req.params.id, req.body, req.user.id);
  res.json({
    message: "Action recorded successfully",
    action: result,
  });
});

export const getReportedContent = asyncHandler(async (req, res) => {  
  const content = await getReportedContentService(req.params.id);  
  res.json({ content });  
});
