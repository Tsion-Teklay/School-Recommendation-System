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
        const features = school.features ? JSON.parse(school.features) : {};

        // Skip if no features stored
        if (!features || Object.keys(features).length === 0) continue;

        trainingRows.push({
          curriculum_score: features.scores?.curriculum ?? 0,
          budget_score: features.scores?.budget ?? 0,
          distance_score: features.scores?.distance ?? 0,
          rating_score: features.scores?.rating ?? 0,
          facilities_score: features.scores?.facilities ?? 0,
          verification_score: features.scores?.verification ?? 0,
          school_type_score: features.scores?.school_type ?? 0,
          passing_rate_score: features.scores?.passing_rate ?? 0,
          national_exam_score: features.scores?.national_exam ?? 0,
          // Add new features if available
          total_students_score: features.scores?.total_students ?? 0,
          gender_balance_score: features.scores?.gender_balance ?? 0,
          achievement_score: features.scores?.achievement_score ?? 0,
          achievement_count_score: features.scores?.achievement_count ?? 0,
          staff_quality_score: features.scores?.staff_quality ?? 0,
          follower_count_score: features.scores?.follower_count ?? 0,
          review_count_score: features.scores?.review_count ?? 0,
          total_achievement_score: features.scores?.total_achievement_score ?? 0,
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
