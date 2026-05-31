import { z } from "zod";
import { paginationQuery } from "./common.schema.js";

/**
 * Discussion forum schemas.
 *
 * The forum is intentionally minimal: top-level posts and one level of
 * replies (threadId points at the parent post). Content moderation runs
 * server-side, not in Zod, so the validator is a happy little length check.
 */
export const createForumPostBodySchema = z.object({
  content: z.string().trim().min(1, "Content is required").max(5000),
});

export const replyBodySchema = z.object({
  content: z.string().trim().min(1, "Content is required").max(5000),
});

export const updateForumPostBodySchema = z.object({
  content: z.string().trim().min(1, "Content is required").max(5000),
});

export const listForumPostsQuerySchema = z.object({
  ...paginationQuery,
});
