import '../../demographics/data/demographics_dtos.dart';  
import '../../achievements/data/achievement_dtos.dart';

class DashboardSummary {
  final int totalUsers;
  final int totalSchools;
  final int totalReviews;
  final int totalAnnouncements;
  final int totalReports;
  final int totalForumPosts;
  final int totalFollows;
  final double averageRating;

  const DashboardSummary({
    required this.totalUsers,
    required this.totalSchools,
    required this.totalReviews,
    required this.totalAnnouncements,
    required this.totalReports,
    required this.totalForumPosts,
    required this.totalFollows,
    required this.averageRating,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }
    return DashboardSummary(
      totalUsers: parseInt(json['totalUsers']),
      totalSchools: parseInt(json['totalSchools']),
      totalReviews: parseInt(json['totalReviews']),
      totalAnnouncements: parseInt(json['totalAnnouncements']),
      totalReports: parseInt(json['totalReports']),
      totalForumPosts: parseInt(json['totalForumPosts']),
      totalFollows: parseInt(json['totalFollows']),
      averageRating: parseDouble(json['averageRating']),
    );
  }
}

class TopSchool {
  final int id;
  final String schoolName;
  final double rating;
  final int reviewCount;
  final String verificationStatus;
  const TopSchool({
    required this.id,
    required this.schoolName,
    required this.rating,
    required this.reviewCount,
    required this.verificationStatus,
  });

  factory TopSchool.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }
    return TopSchool(
      id: parseInt(json['id']),
      schoolName: (json['schoolName'] ?? '?') as String,
      rating: parseDouble(json['rating']),
      reviewCount: parseInt(json['reviewCount']),
      verificationStatus:
          (json['verificationStatus'] ?? 'PENDING') as String,
    );
  }
}

class MostFollowed {
  final int schoolId;
  final String? schoolName;
  final int followers;
  const MostFollowed({
    required this.schoolId,
    required this.schoolName,
    required this.followers,
  });

  factory MostFollowed.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    return MostFollowed(
      schoolId: parseInt(json['schoolId']),
      schoolName: json['schoolName'] as String?,
      followers: parseInt(json['followers']),
    );
  }
}

class Dashboard {
  final DashboardSummary summary;
  final Map<String, int> usersByRole;
  final Map<String, int> schoolsByVerification;
  final Map<String, int> schoolsBySubcity;
  final Map<String, int> reportsByStatus;
  final List<TopSchool> topSchools;
  final List<MostFollowed> mostFollowed;
  final List<MoeRankedSchool> moeRanking;
  final List<Map<String, dynamic>> signupsLast30Days;

  const Dashboard({
    required this.summary,
    required this.usersByRole,
    required this.schoolsByVerification,
    required this.schoolsBySubcity,
    required this.reportsByStatus,
    required this.topSchools,
    required this.mostFollowed,
    required this.moeRanking,  
    required this.signupsLast30Days,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    Map<String, int> intMap(Map? raw) {
      final out = <String, int>{};
      raw?.forEach((k, v) {
        if (v is num) {
          out[k.toString()] = v.toInt();
        } else if (v is String) {
          out[k.toString()] = int.tryParse(v) ?? 0;
        }
      });
      return out;
    }
    return Dashboard(
      summary: DashboardSummary.fromJson(
        (json['summary'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      usersByRole: intMap(json['usersByRole'] as Map?),
      schoolsByVerification:
          intMap(json['schoolsByVerification'] as Map?),
      schoolsBySubcity:
          intMap(json['schoolsBySubcity'] as Map?),
      reportsByStatus: intMap(json['reportsByStatus'] as Map?),
      topSchools: (json['topSchools'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(TopSchool.fromJson)
          .toList(),
      mostFollowed: (json['mostFollowed'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(MostFollowed.fromJson)
          .toList(),
      moeRanking: (json['moeRanking'] as List?)  
              ?.map((e) => MoeRankedSchool.fromJson(e as Map<String, dynamic>))  
              .toList() ??  
          [],
      signupsLast30Days: (json['signupsLast30Days'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .toList(),
    );
  }
}

class MoeRankedSchool {
  final int schoolId;
  final String schoolName;
  final int totalScore;
  final MoeRankingBreakdown breakdown;

  const MoeRankedSchool({
    required this.schoolId,
    required this.schoolName,
    required this.totalScore,
    required this.breakdown,
  });

  factory MoeRankedSchool.fromJson(Map<String, dynamic> json) {
    return MoeRankedSchool(
      schoolId: json['schoolId'] as int,
      schoolName: json['schoolName'] as String,
      totalScore: json['totalScore'] as int,
      breakdown: MoeRankingBreakdown.fromJson(
        json['breakdown'] as Map<String, dynamic>,
      ),
    );
  }
}

class MoeRankingBreakdown {
  final int rating;
  final int verification;
  final int facilities;
  final int achievement;
  final int genderBalance;
  final int passingRate;
  final int nationalExam;

  const MoeRankingBreakdown({
    required this.rating,
    required this.verification,
    required this.facilities,
    required this.achievement,
    required this.genderBalance,
    required this.passingRate,
    required this.nationalExam,
  });

  factory MoeRankingBreakdown.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    return MoeRankingBreakdown(
      rating: parseInt(json['rating']),
      verification: parseInt(json['verification']),
      facilities: parseInt(json['facilities']),
      achievement: parseInt(json['achievement']),
      genderBalance: parseInt(json['genderBalance']),
      passingRate: parseInt(json['passingRate']),
      nationalExam: parseInt(json['nationalExam']),
    );
  }
}

class SchoolAnalytics {
  final double achievementScore;
  final double genderBalanceIndex;
  final double yearOverYearGrowth;
  final double percentileRanking;
  final double parentEngagementScore;
  final double communityTrustScore;
  final double staffQualityScore;
  final List<SchoolDemographics> demographics;
  final List<Achievement> achievements;

  SchoolAnalytics({
    required this.achievementScore,
    required this.genderBalanceIndex,
    required this.yearOverYearGrowth,
    required this.percentileRanking,
    required this.parentEngagementScore,
    required this.communityTrustScore,
    required this.staffQualityScore,
    required this.demographics,
    required this.achievements,
  });

  factory SchoolAnalytics.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }
    return SchoolAnalytics(
      achievementScore: parseDouble(json['achievementScore']),
      genderBalanceIndex: parseDouble(json['genderBalanceIndex']),
      yearOverYearGrowth: parseDouble(json['yearOverYearGrowth']),
      percentileRanking: parseDouble(json['percentileRanking']),
      parentEngagementScore: parseDouble(json['parentEngagementScore']),
      communityTrustScore: parseDouble(json['communityTrustScore']),
      staffQualityScore: parseDouble(json['staffQualityScore']),
      demographics: (json['demographics'] as List? ?? const [])
          .map((e) => SchoolDemographics.fromJson(e as Map<String, dynamic>))
          .toList(),
      achievements: (json['achievements'] as List? ?? const [])
          .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}