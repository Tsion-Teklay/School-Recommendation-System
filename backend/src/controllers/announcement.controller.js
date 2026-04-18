import { asyncHandler } from "../middlewares/async.middleware.js";
import {
  createAnnouncement,
  getAllAnnouncements,
  getAnnouncementById,
  updateAnnouncement,
  deleteAnnouncement,
} from "../services/announcement.service.js";

export const create = asyncHandler(async (req, res) => {
  const announcement = await createAnnouncement(req.body, req.user);
  res.status(201).json({
    message: "Announcement created successfully",
    announcement,
  });
});

export const getAll = asyncHandler(async (req, res) => {
  const result = await getAllAnnouncements(req.query);
  res.json({
    message: "Announcements fetched successfully",
    ...result,
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
