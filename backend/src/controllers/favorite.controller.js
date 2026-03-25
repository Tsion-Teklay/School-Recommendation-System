import {
  addFavorite,
  getMyFavorites,
  removeFavorite,
} from "../services/favorite.service.js";

// ✅ Add
export async function add(req, res) {
  try {
    // FIX: Changed req.user.userId to req.user.id
    const favorite = await addFavorite(
      req.user.id, 
      req.params.schoolId
    );

    res.status(201).json({
      message: "Added to favorites",
      favorite,
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

// ✅ Get my favorites
export async function getMine(req, res) {
  try {
    // FIX: Changed req.user.userId to req.user.id
    const favorites = await getMyFavorites(req.user.id);

    res.json({
      message: "Favorites fetched",
      data: favorites,
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

// ✅ Remove
export async function remove(req, res) {
  try {
    // FIX: Changed req.user.userId to req.user.id
    const result = await removeFavorite(
      req.user.id,
      req.params.schoolId
    );

    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}