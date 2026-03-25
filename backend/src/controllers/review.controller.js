import {
  createReview,
  getReviewsBySchool,
  updateReview,
  deleteReview,
} from "../services/review.service.js";

// ✅ Create
export async function create(req, res) {
  try {
    const review = await createReview(
      req.user.id, // FIX: userId -> id
      req.params.schoolId,
      req.body
    );

    res.status(201).json({
      message: "Review created",
      review,
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

// ✅ Get by school
export async function getBySchool(req, res) {
  try {
    const reviews = await getReviewsBySchool(req.params.schoolId);

    res.json({
      message: "Reviews fetched",
      data: reviews,
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

// ✅ Update
export async function update(req, res) {
  try {
    const review = await updateReview(
      req.user.id, // FIX: userId -> id
      req.params.id,
      req.body
    );

    res.json({
      message: "Review updated",
      review,
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
    const result = await deleteReview(
      req.user.id, // FIX: userId -> id
      req.params.id
    );

    res.json(result);
  } catch (err) {
    if (err.message.includes("authorized")) {
      return res.status(403).json({ error: err.message });
    }
    res.status(400).json({ error: err.message });
  }
}