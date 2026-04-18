import { z } from "zod";

/** Route param: `:id` coerced into a positive integer. */
export const idParamsSchema = z.object({
  id: z.coerce.number().int().positive(),
});

/** Route param: `:schoolId` coerced into a positive integer. */
export const schoolIdParamsSchema = z.object({
  schoolId: z.coerce.number().int().positive(),
});

/** Shared pagination for list endpoints. */
export const paginationQuery = {
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(10),
};
