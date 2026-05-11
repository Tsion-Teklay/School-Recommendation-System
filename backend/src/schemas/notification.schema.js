import { z } from "zod";
import { paginationQuery } from "./common.schema.js";

export const listNotificationsQuerySchema = z.object({
  unread: z.enum(["true", "false"]).optional(),
  ...paginationQuery,
});
