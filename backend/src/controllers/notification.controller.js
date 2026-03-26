import {
  getMyNotifications,
  markAsRead,
} from "../services/notification.service.js";

// ✅ Get My Notifications
export async function getMy(req, res) {
  try {
    const result = await getMyNotifications(req.user.id, req.query);

    res.json({
      message: "Notifications fetched successfully",
      ...result,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

// ✅ Mark as Read
export async function markRead(req, res) {
  try {
    const notification = await markAsRead(
      req.params.id,
      req.user.id
    );

    res.json({
      message: "Notification marked as read",
      notification,
    });
  } catch (err) {
    if (err.message.includes("authorized")) {
      return res.status(403).json({ error: err.message });
    }
    res.status(400).json({ error: err.message });
  }
}