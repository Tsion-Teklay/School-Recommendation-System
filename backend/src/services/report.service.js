import { db } from "../config/db.js";
import { NotFoundError } from "../utils/errors.js";
import { logger } from "../config/logger.js";
import { createNotification } from "./notification.service.js";

// ✅ Create Report
export async function createReport(data, userId) {
  const { targetType, targetId, reason } = data;

  const report = await db.report.create({
    data: {
      reporterId: userId,
      targetType,
      targetId: Number(targetId),
      reason,
    },
  });

  return report;
}

// ✅ Get All Reports (Moderator)
export async function getAllReports(query) {
  const { status } = query;

  const where = {
    ...(status && { status }),
  };

  return db.report.findMany({
    where,
    include: {
      reporter: true,
      actions: true,
    },
    orderBy: { createdAt: "desc" },
  });
}

// ✅ Get Single Report
export async function getReportById(id) {
  const report = await db.report.findUnique({
    where: { id: Number(id) },
    include: {
      reporter: true,
      actions: true,
    },
  });

  if (!report) throw new NotFoundError("Report not found");

  return report;
}

// ✅ Moderator Action
export async function takeAction(reportId, data, moderatorId) {
  const report = await db.report.findUnique({
    where: { id: Number(reportId) },
  });

  if (!report) throw new NotFoundError("Report not found");

  const action = await db.moderatorAction.create({
    data: {
      moderatorId,
      reportId: Number(reportId),
      actionType: data.actionType,
      notes: data.notes,
    },
  });

  await db.report.update({
    where: { id: Number(reportId) },
    data: {
      status: "REVIEWED",
    },
  });

  // 🚀 INTEGRATION: Notify the reporter
  try {
    await createNotification({
      recipientId: report.reporterId,
      recipientType: "PARENT",
      message: `Your report (ID: ${reportId}) has been reviewed.`,
      sourceId: reportId,
      sourceType: "REPORT",
    });
  } catch (error) {
    logger.warn({ err: error, reportId }, "Report notification failed");
  }

  return action;
}
