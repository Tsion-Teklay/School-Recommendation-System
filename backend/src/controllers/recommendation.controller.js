import { getAllSchools } from "../services/school.service.js";
import { getRecommendations } from "../services/recommendation.service.js";

export async function recommend(req, res) {
  try {
    // 1️⃣ Get filtered schools
    const result = await getAllSchools(req.query);

    // 2️⃣ Call recommendation service
    const ranked = await getRecommendations(result.data, req.query);

    res.json({
      message: "Recommendations generated",
      data: ranked,
      meta: result.meta,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}