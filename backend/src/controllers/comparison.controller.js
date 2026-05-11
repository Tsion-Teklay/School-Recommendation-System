import { asyncHandler } from "../middlewares/async.middleware.js";
import {
  createComparison,
  listMyComparisons,
  getComparison,
  deleteComparison,
} from "../services/comparison.service.js";

export const create = asyncHandler(async (req, res) => {
  const comparison = await createComparison(req.user.id, req.body);
  res.status(201).json({
    message: "Comparison created",
    comparison,
  });
});

export const getMine = asyncHandler(async (req, res) => {
  const result = await listMyComparisons(req.user.id, req.query);
  res.json({
    message: "Comparisons fetched",
    ...result,
  });
});

export const getOne = asyncHandler(async (req, res) => {
  const comparison = await getComparison(req.user.id, req.params.id);
  res.json({
    message: "Comparison fetched",
    comparison,
  });
});

export const remove = asyncHandler(async (req, res) => {
  const result = await deleteComparison(req.user.id, req.params.id);
  res.json(result);
});
