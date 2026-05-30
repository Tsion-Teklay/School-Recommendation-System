import { z } from "zod";

const demographicsBaseSchema = z.object({
  schoolId: z.coerce.number().int().positive("School ID must be a positive number"),
  academicYear: z.coerce.number().int().min(2000, "Academic year must be 2000 or later").max(new Date().getFullYear(), "Academic year cannot be in the future"),
  totalStudents: z.coerce.number().int().positive("Total students must be a positive number"),
  girlsCount: z.coerce.number().int().min(0, "Girls count cannot be negative"),
  boysCount: z.coerce.number().int().min(0, "Boys count cannot be negative"),
  passingRate: z.coerce.number().min(0, "Passing rate must be between 0 and 100").max(100, "Passing rate must be between 0 and 100"),
  nationalExamScore: z.coerce.number().min(0, "National exam score must be between 0 and 600").max(600, "National exam score must be between 0 and 600"),
});

export const createDemographicsBodySchema =
  demographicsBaseSchema.refine(
    (data) =>
      data.girlsCount + data.boysCount === data.totalStudents,
    {
      message: (data) => `Total students (${data.totalStudents}) must equal girls (${data.girlsCount}) + boys (${data.boysCount}). Current sum is ${data.girlsCount + data.boysCount}.`,
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
        message: (data) => `Total students (${data.totalStudents}) must equal girls (${data.girlsCount}) + boys (${data.boysCount}). Current sum is ${data.girlsCount + data.boysCount}.`,
        path: ["totalStudents"],
      }
    );