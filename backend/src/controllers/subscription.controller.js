import { asyncHandler } from "../middlewares/async.middleware.js";
import {
  followSchool,
  unfollowSchool,
  listMyFollows,
} from "../services/subscription.service.js";

export const follow = asyncHandler(async (req, res) => {
  const subscription = await followSchool(req.user.id, req.params.schoolId);
  res.status(201).json({
    message: "Followed school",
    subscription,
  });
});

export const unfollow = asyncHandler(async (req, res) => {
  const result = await unfollowSchool(req.user.id, req.params.schoolId);
  res.json(result);
});

export const getMine = asyncHandler(async (req, res) => {
  const result = await listMyFollows(req.user.id, req.query);
  res.json({
    message: "Follows fetched",
    ...result,
  });
});
