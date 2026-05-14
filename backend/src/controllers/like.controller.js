import asyncHandler from "../middlewares/asyncHandler.js";  
import { toggleLike, getLikeCount, getUserLikeStatus } from "../services/like.service.js";  
  
export const toggleLikeHandler = asyncHandler(async (req, res) => {  
  const { targetType, targetId } = req.body;  
  const result = await toggleLike(req.user.id, targetType, targetId);  
  res.status(200).json(result);  
});  
  
export const getLikeCountHandler = asyncHandler(async (req, res) => {  
  const { targetType, targetId } = req.params;  
  const count = await getLikeCount(targetType, targetId);  
  res.status(200).json({ count });  
});  
  
export const getUserLikeStatusHandler = asyncHandler(async (req, res) => {  
  const { targetType, targetId } = req.params;  
  const status = await getUserLikeStatus(req.user.id, targetType, targetId);  
  res.status(200).json(status);  
});