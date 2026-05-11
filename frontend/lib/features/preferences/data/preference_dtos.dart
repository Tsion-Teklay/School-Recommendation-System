// Hand-rolled DTOs that mirror the Phase 10 backend preference shape.
//
// The backend returns nulls (not a 404) when nothing has been saved yet — the
// preferences screen wants an empty form, not an error. Decimal/Int fields
// can arrive as either `String` or `num` from MySQL via Prisma, so the
// parsing helper accepts both.

double? _asDouble(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int? _asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

enum PreferredCurriculum { local, international }

extension PreferredCurriculumX on PreferredCurriculum {
  String toWire() => this == PreferredCurriculum.local ? 'LOCAL' : 'INTERNATIONAL';
  String label() =>
      this == PreferredCurriculum.local ? 'Local (Ethiopian)' : 'International';

  static PreferredCurriculum? tryFromWire(String? s) {
    switch (s) {
      case 'LOCAL':
        return PreferredCurriculum.local;
      case 'INTERNATIONAL':
        return PreferredCurriculum.international;
      default:
        return null;
    }
  }
}

/// The merged response from GET /api/preferences/me — combines the parent's
/// home-pin (address/lat/lng) and the recommender criteria
/// (min/max budget, curriculum, distance radius) so the screen hydrates both
/// sections with a single round-trip.
class ParentPreferences {
  final double? minBudget;
  final double? maxBudget;
  final PreferredCurriculum? curriculum;
  final int? distanceKm;
  final String? address;
  final double? latitude;
  final double? longitude;

  const ParentPreferences({
    this.minBudget,
    this.maxBudget,
    this.curriculum,
    this.distanceKm,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory ParentPreferences.empty() => const ParentPreferences();

  factory ParentPreferences.fromJson(Map<String, dynamic> json) {
    return ParentPreferences(
      minBudget: _asDouble(json['minBudget']),
      maxBudget: _asDouble(json['maxBudget']),
      curriculum:
          PreferredCurriculumX.tryFromWire(json['curriculum'] as String?),
      distanceKm: _asInt(json['distance']),
      address: json['address'] as String?,
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
    );
  }

  bool get hasHomePin =>
      address != null && latitude != null && longitude != null;
}
