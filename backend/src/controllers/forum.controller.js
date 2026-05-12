import { asyncHandler } from "../middlewares/async.middleware.js";
import * as forum from "../services/forum.service.js";

export const createPost = asyncHandler(async (req, res) => {
  const post = await forum.createPost(req.user.id, req.body);
  res.status(201).json({ message: "Post created", post });
});

export const listPosts = asyncHandler(async (req, res) => {
  const result = await forum.listTopLevelPosts(req.query);
  res.json({ message: "Posts fetched", ...result });
});

export const getPost = asyncHandler(async (req, res) => {
  const post = await forum.getPostWithReplies(req.params.id);
  res.json({ message: "Post fetched", post });
});

export const reply = asyncHandler(async (req, res) => {
  const post = await forum.replyToPost(req.user.id, req.params.id, req.body);
  res.status(201).json({ message: "Reply posted", post });
});

export const updatePost = asyncHandler(async (req, res) => {
  const post = await forum.updatePost(req.user.id, req.params.id, req.body);
  res.json({ message: "Post updated", post });
});

export const deletePost = asyncHandler(async (req, res) => {
  const result = await forum.deletePost(req.user, req.params.id);
  res.json(result);
});

export const getAnnouncementCommentsHandler = asyncHandler(async (req, res) => {  
  const { announcementId } = req.params;  
  const comments = await getAnnouncementComments(announcementId);  
  res.status(200).json({ data: comments });  
});
