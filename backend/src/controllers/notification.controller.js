import { asyncHandler } from "../middlewares/async.middleware.js";
import {
  getMyNotifications,
  markAsRead,
} from "../services/notification.service.js";

export const getMy = asyncHandler(async (req, res) => {
  const result = await getMyNotifications(req.user.id, req.query);
  res.json({
    message: "Notifications fetched successfully",
    ...result,
  });
});

export const markRead = asyncHandler(async (req, res) => {
  const notification = await markAsRead(req.params.id, req.user.id);
  res.json({
    message: "Notification marked as read",
    notification,
  });
});
