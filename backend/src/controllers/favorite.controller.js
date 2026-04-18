import { asyncHandler } from "../middlewares/async.middleware.js";
import {
  addFavorite,
  getMyFavorites,
  removeFavorite,
} from "../services/favorite.service.js";

export const add = asyncHandler(async (req, res) => {
  const favorite = await addFavorite(req.user.id, req.params.schoolId);
  res.status(201).json({
    message: "Added to favorites",
    favorite,
  });
});

export const getMine = asyncHandler(async (req, res) => {
  const favorites = await getMyFavorites(req.user.id);
  res.json({
    message: "Favorites fetched",
    data: favorites,
  });
});

export const remove = asyncHandler(async (req, res) => {
  const result = await removeFavorite(req.user.id, req.params.schoolId);
  res.json(result);
});
