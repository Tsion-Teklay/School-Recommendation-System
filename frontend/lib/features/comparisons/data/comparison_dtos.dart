import '../../schools/data/school_dtos.dart';

/// One saved comparison. The backend includes the full schools array (with the
/// `SCHOOL_SELECT` projection from `comparison.service.js`), so we re-use the
/// `School` DTO and just ignore the fields it doesn't populate (admin,
/// followerCount).
class Comparison {
  final int id;
  final int parentId;
  final List<String> metrics;
  final DateTime createdAt;
  final List<School> schools;

  const Comparison({
    required this.id,
    required this.parentId,
    required this.metrics,
    required this.createdAt,
    required this.schools,
  });

  factory Comparison.fromJson(Map<String, dynamic> json) {
    final rawMetrics = (json['metrics'] as List?) ?? const [];
    final rawSchools = (json['schools'] as List).cast<Map<String, dynamic>>();
    return Comparison(
      id: (json['id'] as num).toInt(),
      parentId: (json['parentId'] as num).toInt(),
      metrics: rawMetrics.map((m) => m.toString()).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      schools: rawSchools.map(School.fromJson).toList(),
    );
  }
}
