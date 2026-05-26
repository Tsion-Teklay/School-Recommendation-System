import { db as prisma } from "../config/db.js";

export async function getTrainingData(req, res) {
  try {
    // STEP 1
    // Fetch recommendation histories
    const histories = await prisma.recommendationHistory.findMany({
      where: {},

      include: {
        recommendedSchools: true,
      },
    });

    // STEP 2
    // Flatten all rows
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
          school_level_score: features.school_level_score ?? 0,
          passing_rate_score: features.passing_rate_score ?? 0,
          national_exam_score: features.national_exam_score ?? 0,

          achievement_score: features.achievement_score ?? 0,
          gender_balance_score: features.gender_balance_score ?? 0,
          total_students_score: features.total_students_score ?? 0,
          staff_quality_score: features.staff_quality_score ?? 0,

          parent_engagement_score: features.parent_engagement_score ?? 0,
          community_trust_score: features.community_trust_score ?? 0,
          follower_count_score: features.follower_count_score ?? 0,

          year_over_year_growth_score:
            features.year_over_year_growth_score ?? 0,

          parent_min_budget: history.preferenceCriteria?.[0]?.minBudget ?? 0,
          parent_max_budget:
            history.preferenceCriteria?.[0]?.maxBudget ?? 100000,
          parent_curriculum:
            history.preferenceCriteria?.[0]?.curriculum ?? null,
          parent_distance: history.preferenceCriteria?.[0]?.distance ?? 25,
          parent_school_type:
            history.preferenceCriteria?.[0]?.schoolType ?? null,
          parent_school_level:
            history.preferenceCriteria?.[0]?.schoolLevel ?? null,

          academic_year: features.academic_year ?? null,

          outcome,
        });
      }
    }

    // STEP 3
    // Return flattened ML data
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
