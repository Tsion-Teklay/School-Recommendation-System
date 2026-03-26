import {
  createAnnouncement,
  getAllAnnouncements,
  getAnnouncementById,
  updateAnnouncement,
  deleteAnnouncement,
} from "../services/announcement.service.js";

// ✅ Create
export async function create(req, res) {
  try {
    const announcement = await createAnnouncement(req.body, req.user);

    res.status(201).json({
      message: "Announcement created successfully",
      announcement,
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

// ✅ Get All
export async function getAll(req, res) {
  try {
    const result = await getAllAnnouncements(req.query);

    res.json({
      message: "Announcements fetched successfully",
      ...result,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

// ✅ Get One
export async function getOne(req, res) {
  try {
    const announcement = await getAnnouncementById(req.params.id);

    res.json({
      message: "Announcement fetched successfully",
      announcement,
    });
  } catch (err) {
    res.status(404).json({ error: err.message });
  }
}

// ✅ Update
export async function update(req, res) {
  try {
    const announcement = await updateAnnouncement(
      req.params.id,
      req.body,
      req.user.id
    );

    res.json({
      message: "Announcement updated successfully",
      announcement,
    });
  } catch (err) {
    if (err.message.includes("authorized")) {
      return res.status(403).json({ error: err.message });
    }
    res.status(400).json({ error: err.message });
  }
}

// ✅ Delete
export async function remove(req, res) {
  try {
    const result = await deleteAnnouncement(
      req.params.id,
      req.user.id
    );

    res.json(result);
  } catch (err) {
    if (err.message.includes("authorized")) {
      return res.status(403).json({ error: err.message });
    }
    res.status(400).json({ error: err.message });
  }
}