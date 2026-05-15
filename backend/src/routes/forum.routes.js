import express from "express";
import * as controller from "../controllers/forum.controller.js";
import { authenticate } from "../middlewares/auth.middleware.js";
import { validate } from "../middlewares/validate.middleware.js";
import { idParamsSchema } from "../schemas/common.schema.js";
import {
  createForumPostBodySchema,
  replyBodySchema,
  updateForumPostBodySchema,
  listForumPostsQuerySchema,
} from "../schemas/forum.schema.js";

const router = express.Router();

/**
 * @openapi
 * /api/forum:
 *   get:
 *     tags: [Forum]
 *     summary: List top-level forum posts (paginated)
 *   post:
 *     tags: [Forum]
 *     summary: Create a top-level forum post (any authenticated user)
 *     security: [{ bearerAuth: [] }]
 */
router.get(
  "/",
  validate({ query: listForumPostsQuerySchema }),
  controller.listPosts
);

router.post(
  "/",
  authenticate,
  validate({ body: createForumPostBodySchema }),
  controller.createPost
);

/**
 * @openapi
 * /api/forum/announcement/{announcementId}:
 *   get:
 *     tags: [Forum]
 *     summary: Get comments on an announcement (public)
 *   post:
 *     tags: [Forum]
 *     summary: Post a comment on an announcement (any authenticated user)
 *     security: [{ bearerAuth: [] }]
 */
router.get(
  "/announcement/:announcementId",
  controller.getAnnouncementCommentsHandler
);

router.post(
  "/announcement/:announcementId",
  authenticate,
  controller.createAnnouncementCommentHandler
);

/**
 * @openapi
 * /api/forum/{id}:
 *   get:
 *     tags: [Forum]
 *     summary: Get a forum post + its replies
 *   put:
 *     tags: [Forum]
 *     summary: Edit a forum post (author only)
 *     security: [{ bearerAuth: [] }]
 *   delete:
 *     tags: [Forum]
 *     summary: Delete a forum post (author or MODERATOR)
 *     security: [{ bearerAuth: [] }]
 */
router.get(
  "/:id",
  validate({ params: idParamsSchema }),
  controller.getPost
);

router.put(
  "/:id",
  authenticate,
  validate({ params: idParamsSchema, body: updateForumPostBodySchema }),
  controller.updatePost
);

router.delete(
  "/:id",
  authenticate,
  validate({ params: idParamsSchema }),
  controller.deletePost
);

/**
 * @openapi
 * /api/forum/{id}/replies:
 *   post:
 *     tags: [Forum]
 *     summary: Reply to a forum post (any authenticated user)
 *     security: [{ bearerAuth: [] }]
 */
router.post(
  "/:id/replies",
  authenticate,
  validate({ params: idParamsSchema, body: replyBodySchema }),
  controller.reply
);

export default router;

