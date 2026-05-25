import { z } from "zod";

const demographicsBaseSchema = z.object({
  schoolId: z.coerce.number().int().positive(),
  academicYear: z.coerce.number().int().min(2000).max(2100),
  totalStudents: z.coerce.number().int().positive(),
  girlsCount: z.coerce.number().int().min(0),
  boysCount: z.coerce.number().int().min(0),
  passingRate: z.coerce.number().min(0).max(100),
  nationalExamScore: z.coerce.number().min(0).max(100),
});

export const createDemographicsBodySchema =
  demographicsBaseSchema.refine(
    (data) =>
      data.girlsCount + data.boysCount === data.totalStudents,
    {
      message: "girlsCount + boysCount must equal totalStudents",
      path: ["totalStudents"],
    }
  );

export const updateDemographicsBodySchema =
  demographicsBaseSchema
    .partial()
    .refine(
      (data) => {
        // only validate if all 3 fields are present
        if (
          data.totalStudents === undefined ||
          data.girlsCount === undefined ||
          data.boysCount === undefined
        ) {
          return true;
        }

        return (
          data.girlsCount + data.boysCount ===
          data.totalStudents
        );
      },
      {
        message: "girlsCount + boysCount must equal totalStudents",
        path: ["totalStudents"],
      }
    );