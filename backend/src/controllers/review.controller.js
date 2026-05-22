import { asyncHandler } from "../middlewares/async.middleware.js";
import {
  createReview,
  getReviewsBySchool,
  updateReview,
  deleteReview,
  getRatingDistribution as getRatingDistributionService,
} from "../services/review.service.js";

export const create = asyncHandler(async (req, res) => {
  const review = await createReview(
    req.user.id,
    req.params.schoolId,
    req.body
  );
  res.status(201).json({
    message: "Review created",
    review,
  });
});

export const getBySchool = asyncHandler(async (req, res) => {
  const reviews = await getReviewsBySchool(req.params.schoolId);
  res.json({
    message: "Reviews fetched",
    data: reviews,
  });
});

export const update = asyncHandler(async (req, res) => {
  const review = await updateReview(req.user.id, req.params.id, req.body);
  res.json({
    message: "Review updated",
    review,
  });
});

export const remove = asyncHandler(async (req, res) => {
  const result = await deleteReview(req.user.id, req.params.id);
  res.json(result);
});

export const getRatingDistribution = asyncHandler(async (req, res) => {  
  const { schoolId } = req.params;  
  const distribution = await getRatingDistributionService(schoolId);  
  res.json({ distribution });  
});