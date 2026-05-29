import { db as prisma } from "../config/db.js";

export async function getTrainingData(req, res) {
  try {
    // STEP 1: Fetch recommendation histories
    const histories = await prisma.recommendationHistory.findMany({
      where: {},
      include: {
        recommendedSchools: true,
      },
    });

    // STEP 2: Flatten all rows
    const trainingRows = [];

    for (const history of histories) {
      // Convert interaction into ML label
      const outcome = history.interactionResult === "OPENED" ? 1 : 0;

      // Each recommended school becomes a row
      for (const school of history.recommendedSchools) {
        const features = school.features;

        // Skip if no features stored
        if (!features) continue;

        trainingRows.push({
          curriculum_score: features.curriculum_score ?? 0,
          budget_score: features.budget_score ?? 0,
          distance_score: features.distance_score ?? 0,
          rating_score: features.rating_score ?? 0,
          facilities_score: features.facilities_score ?? 0,
          verification_score: features.verification_score ?? 0,
          school_type_score: features.school_type_score ?? 0,
          passing_rate_score: features.passing_rate_score ?? 0,
          national_exam_score: features.national_exam_score ?? 0,
          // Add new features if available
          total_students_score: features.total_students_score ?? 0,
          gender_balance_score: features.gender_balance_score ?? 0,
          achievement_score: features.achievement_score ?? 0,
          achievement_count_score: features.achievement_count_score ?? 0,
          staff_quality_score: features.staff_quality_score ?? 0,
          follower_count_score: features.follower_count_score ?? 0,
          review_count_score: features.review_count_score ?? 0,
          total_achievement_score: features.total_achievement_score ?? 0,
          outcome,
        });
      }
    }

    // STEP 3: Return flattened ML data
    return res.json({
      count: trainingRows.length,
      data: trainingRows,
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({
      success: false,
      error: err.message,
    });
  }
}
