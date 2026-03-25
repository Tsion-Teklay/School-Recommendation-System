// TEMP: mock external service

export async function getRecommendations(schools, preferences) {
  // 🧠 Simple ranking logic (mock)
  let ranked = [...schools];

  // Example scoring:
  ranked = ranked.map((school) => {
    let score = 0;

    // 🎓 Curriculum match
    if (preferences.curriculum && school.curriculum === preferences.curriculum) {
      score += 5;
    }

    // 💰 Budget proximity
    if (preferences.maxFee) {
      const diff = Math.abs(Number(preferences.maxFee) - Number(school.tuitionFee));
      score += Math.max(0, 5 - diff / 1000);
    }

    return { ...school, score };
  });

  // 🔽 Sort by score DESC
  ranked.sort((a, b) => b.score - a.score);

  return ranked;
}