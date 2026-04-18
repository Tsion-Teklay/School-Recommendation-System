import { asyncHandler } from "../middlewares/async.middleware.js";
import { getAllSchools } from "../services/school.service.js";
import { getRecommendations } from "../services/recommendation.service.js";

export const recommend = asyncHandler(async (req, res) => {
  // 1️⃣ Get filtered schools
  const result = await getAllSchools(req.query);

  // 2️⃣ Rank them using the (mock) recommendation engine
  const ranked = await getRecommendations(result.data, req.query);

  res.json({
    message: "Recommendations generated",
    data: ranked,
    meta: result.meta,
  });
});
