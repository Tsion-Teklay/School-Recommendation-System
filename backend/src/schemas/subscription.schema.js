import { z } from "zod";
import { paginationQuery } from "./common.schema.js";

/** Query params for listing the current parent's school subscriptions. */
export const listFollowsQuerySchema = z.object({
  ...paginationQuery,
});
