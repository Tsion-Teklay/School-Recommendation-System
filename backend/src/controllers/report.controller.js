import {
  createReport,
  getAllReports,
  getReportById,
  takeAction,
} from "../services/report.service.js";

// ✅ Create
export async function create(req, res) {
  try {
    const report = await createReport(req.body, req.user.id);

    res.status(201).json({
      message: "Report submitted successfully",
      report,
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

// ✅ Get All (Moderator)
export async function getAll(req, res) {
  try {
    const reports = await getAllReports(req.query);

    res.json({
      message: "Reports fetched successfully",
      data: reports,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

// ✅ Get One
export async function getOne(req, res) {
  try {
    const report = await getReportById(req.params.id);

    res.json({
      message: "Report fetched successfully",
      report,
    });
  } catch (err) {
    res.status(404).json({ error: err.message });
  }
}

// ✅ Moderator Action
export async function action(req, res) {
  try {
    const result = await takeAction(
      req.params.id,
      req.body,
      req.user.id
    );

    res.json({
      message: "Action recorded successfully",
      action: result,
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}