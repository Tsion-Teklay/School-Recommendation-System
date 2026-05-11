import { asyncHandler } from "../middlewares/async.middleware.js";
import {
  createAnnouncement,
  getAllAnnouncements,
  getAnnouncementById,
  updateAnnouncement,
  deleteAnnouncement,
  setAnnouncementImage,
  clearAnnouncementImage,
} from "../services/announcement.service.js";
import { relativeUrl } from "../config/uploads.js";
import { ValidationError } from "../utils/errors.js";

export const create = asyncHandler(async (req, res) => {
  const announcement = await createAnnouncement(req.body, req.user);
  res.status(201).json({
    message: "Announcement created successfully",
    announcement,
  });
});

export const getAll = asyncHandler(async (req, res) => {
  // Phase 11 — pass `req.user` so the `followedOnly` filter can resolve. The
  // listing endpoint stays public, so `user` may be undefined for anonymous
  // visitors; the service handles that.
  const result = await getAllAnnouncements(req.query, req.user);
  res.json({
    message: "Announcements fetched successfully",
    ...result,
  });
});

export const uploadImage = asyncHandler(async (req, res) => {
  if (!req.file) {
    throw new ValidationError("Missing image file under field 'image'");
  }
  const announcement = await setAnnouncementImage({
    id: req.params.id,
    imageUrl: relativeUrl(req.file),
    userId: req.user.id,
  });
  res.json({
    message: "Announcement image uploaded successfully",
    announcement,
  });
});

export const removeImage = asyncHandler(async (req, res) => {
  const announcement = await clearAnnouncementImage({
    id: req.params.id,
    userId: req.user.id,
  });
  res.json({
    message: "Announcement image cleared successfully",
    announcement,
  });
});

export const getOne = asyncHandler(async (req, res) => {
  const announcement = await getAnnouncementById(req.params.id);
  res.json({
    message: "Announcement fetched successfully",
    announcement,
  });
});

export const update = asyncHandler(async (req, res) => {
  const announcement = await updateAnnouncement(
    req.params.id,
    req.body,
    req.user.id
  );
  res.json({
    message: "Announcement updated successfully",
    announcement,
  });
});

export const remove = asyncHandler(async (req, res) => {
  const result = await deleteAnnouncement(req.params.id, req.user.id);
  res.json(result);
});
