import { z } from "zod";
import { paginationQuery } from "./common.schema.js";

export const recommendationsQuerySchema = z.object({
  curriculum: z.enum(["LOCAL", "INTERNATIONAL"]).optional(),
  budget: z.coerce.number().nonnegative().optional(),
  minFee: z.coerce.number().nonnegative().optional(),
  maxFee: z.coerce.number().nonnegative().optional(),
  search: z.string().trim().optional(),
  ...paginationQuery,
});
