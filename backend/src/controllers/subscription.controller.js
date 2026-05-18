import { db } from "../config/db.js"; // Or your relative path to the Prisma client instance
import { asyncHandler } from "../middlewares/async.middleware.js";
import {
  followSchool,
  unfollowSchool,
  listMyFollows,
} from "../services/subscription.service.js";

export const follow = asyncHandler(async (req, res) => {
  const schoolIdNum = parseInt(req.params.schoolId);
  const subscription = await followSchool(req.user.id, schoolIdNum);

  // Reactive Telemetry: Update interaction status if the school was part of a recommendation history chain
  await db.recommendedSchool.updateMany({
    where: {
      schoolId: schoolIdNum,
      recommendation: {
        parentId: req.user.id
      }
    },
    data: { interactionResult: "FOLLOWED" }
  });

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