import { asyncHandler } from "../middlewares/async.middleware.js";
import { relativeUrl } from "../config/uploads.js";
import {
  submitVerificationRequest,
  listVerificationRequests,
  getVerificationRequest,
  reviewVerificationRequest,
} from "../services/verification.service.js";

export const submit = asyncHandler(async (req, res) => {
  // multer populates req.files; map to public URLs before persisting.
  const documents = (req.files || []).map((f) => ({
    url: relativeUrl(f),
    originalName: f.originalname,
    size: f.size,
    mimeType: f.mimetype,
  }));

  const created = await submitVerificationRequest({
    schoolId: req.params.schoolId,
    userId: req.user.id,
    documents,
    notes: req.body?.notes,
  });

  res.status(201).json({
    message: "Verification request submitted",
    request: created,
  });
});

export const list = asyncHandler(async (req, res) => {
  const result = await listVerificationRequests({
    user: req.user,
    query: req.query,
  });
  res.json({
    message: "Verification requests fetched",
    ...result,
  });
});

export const getOne = asyncHandler(async (req, res) => {
  const request = await getVerificationRequest({
    id: req.params.id,
    user: req.user,
  });
  res.json({ message: "Verification request fetched", request });
});

export const review = asyncHandler(async (req, res) => {
  const updated = await reviewVerificationRequest({
    id: req.params.id,
    user: req.user,
    status: req.body.status,
    reviewNotes: req.body.reviewNotes,
  });
  res.json({
    message: `Verification request ${updated.status.toLowerCase()}`,
    request: updated,
  });
});
