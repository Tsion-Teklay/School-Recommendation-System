import { z } from "zod";

// Preferences hold the recommender's saved parent-side criteria
// (minBudget/maxBudget/curriculum/distance) and — optionally — also let the
// parent set their home pin (address + latitude + longitude on the Parent
// row). The Parent row may not exist yet for users registered via phone-only,
// so the service is responsible for upserting it; this schema just validates
// what the client can send.
export const upsertPreferenceBodySchema = z
  .object({
    minBudget: z.coerce.number().nonnegative().optional(),
    maxBudget: z.coerce.number().nonnegative().optional(),
    curriculum: z.enum(["LOCAL", "INTERNATIONAL"]).optional(),
    distance: z.coerce.number().nonnegative().optional(),
    address: z.string().trim().min(1).max(255).optional(),
    latitude: z.coerce.number().min(-90).max(90).optional(),
    longitude: z.coerce.number().min(-180).max(180).optional(),
    schoolType: z.enum(["PRIVATE", "GOVERNMENT", "CHURCH"]).optional(),
  })
  .refine((val) => Object.keys(val).length > 0, {
    message: "At least one field is required",
  })
  .refine(
    (val) => {
      // lat/lng are paired — either both or neither
      const hasLat = val.latitude != null;
      const hasLng = val.longitude != null;
      return hasLat === hasLng;
    },
    {
      message: "latitude and longitude must be provided together",
      path: ["latitude"],
    }
  );
