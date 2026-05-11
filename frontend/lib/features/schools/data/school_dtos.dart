// Plain-Dart DTOs for the schools / recommendations / follows endpoints.
//
// We keep the same hand-rolled fromJson style as auth_dtos.dart for now —
// the surface is still small and codegen would only obscure the mapping
// from backend column to UI field.

enum Curriculum { local, international }

extension CurriculumX on Curriculum {
  String toWire() => this == Curriculum.local ? 'LOCAL' : 'INTERNATIONAL';

  String label() => this == Curriculum.local ? 'Local' : 'International';

  static Curriculum fromWire(String s) {
    switch (s) {
      case 'LOCAL':
        return Curriculum.local;
      case 'INTERNATIONAL':
        return Curriculum.international;
      default:
        throw ArgumentError('Unknown curriculum: $s');
    }
  }
}

/// Phase 11 — school level (pre-primary / primary / secondary). Stored on
/// the School row and surfaced in filters + detail badges.
enum SchoolLevel { prePrimary, primary, secondary }

extension SchoolLevelX on SchoolLevel {
  String toWire() {
    switch (this) {
      case SchoolLevel.prePrimary:
        return 'PRE_PRIMARY';
      case SchoolLevel.primary:
        return 'PRIMARY';
      case SchoolLevel.secondary:
        return 'SECONDARY';
    }
  }

  String label() {
    switch (this) {
      case SchoolLevel.prePrimary:
        return 'Pre-primary';
      case SchoolLevel.primary:
        return 'Primary';
      case SchoolLevel.secondary:
        return 'Secondary';
    }
  }

  static SchoolLevel? fromWire(String? s) {
    switch (s) {
      case 'PRE_PRIMARY':
        return SchoolLevel.prePrimary;
      case 'PRIMARY':
        return SchoolLevel.primary;
      case 'SECONDARY':
        return SchoolLevel.secondary;
      default:
        return null;
    }
  }
}

/// One entry from `school.facilityImages` (Phase 11). The URL is relative
/// to the API base (e.g. `/uploads/facility-images/abc.png`) — callers
/// concatenate `AppConfig.apiBaseUrl` themselves so this DTO stays plain.
class FacilityImage {
  final int id;
  final String imageUrl;
  const FacilityImage({required this.id, required this.imageUrl});

  factory FacilityImage.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    return FacilityImage(
      id: parseInt(json['id']),
      imageUrl: (json['imageUrl'] ?? '') as String,
    );
  }
}

enum VerificationStatus { pending, verified, rejected }

extension VerificationStatusX on VerificationStatus {
  String label() {
    switch (this) {
      case VerificationStatus.pending:
        return 'Pending verification';
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.rejected:
        return 'Verification rejected';
    }
  }

  static VerificationStatus fromWire(String? s) {
    switch (s) {
      case 'VERIFIED':
        return VerificationStatus.verified;
      case 'REJECTED':
        return VerificationStatus.rejected;
      case 'PENDING':
      default:
        return VerificationStatus.pending;
    }
  }
}

/// Fields common to both list and detail responses. Detail adds `admin` and
/// `followerCount`; list adds the optional `distanceKm` when proximity search
/// is in play. Everything else is the same shape.
class School {
  final int id;
  final String schoolName;
  final String address;
  final String contactEmail;
  final String? contactPhone;
  final Curriculum curriculum;
  final num tuitionFee;
  final String? facilities;
  final double? latitude;
  final double? longitude;
  final num? rating;
  final int? reviewCount;
  final VerificationStatus verificationStatus;

  /// Phase 11 — null when the school hasn't been categorised yet.
  final SchoolLevel? schoolLevel;

  /// Phase 11 — facility images attached to this school. Only populated on
  /// the detail response (`GET /api/schools/:id`); the list endpoint
  /// returns an empty list to keep payloads small.
  final List<FacilityImage> facilityImages;

  /// Only set on detail responses.
  final int? followerCount;

  /// Only set on the proximity-search list path.
  final double? distanceKm;

  const School({
    required this.id,
    required this.schoolName,
    required this.address,
    required this.contactEmail,
    required this.contactPhone,
    required this.curriculum,
    required this.tuitionFee,
    required this.facilities,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.verificationStatus,
    required this.schoolLevel,
    required this.facilityImages,
    required this.followerCount,
    required this.distanceKm,
  });

  factory School.fromJson(Map<String, dynamic> json) {
    // Prisma's MariaDB adapter serializes `Decimal` columns as JSON strings
    // (e.g. `"75000.00"`, `"4.50"`). We accept both `num` and `String` here so
    // a backend rev that switches representation doesn't crash the UI.
    double? coerceDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    num coerceNum(dynamic v, num fallback) {
      if (v == null) return fallback;
      if (v is num) return v;
      return num.tryParse(v.toString()) ?? fallback;
    }

    int? coerceInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    final imgs = (json['facilityImages'] as List?) ?? const [];
    return School(
      id: coerceInt(json['id'])!,
      schoolName: json['schoolName'] as String,
      address: (json['address'] ?? '') as String,
      contactEmail: (json['contactEmail'] ?? '') as String,
      contactPhone: json['contactPhone'] as String?,
      curriculum: CurriculumX.fromWire(json['curriculum'] as String),
      tuitionFee: coerceNum(json['tuitionFee'], 0),
      facilities: json['facilities'] as String?,
      latitude: coerceDouble(json['latitude']),
      longitude: coerceDouble(json['longitude']),
      rating: coerceDouble(json['rating']),
      reviewCount: coerceInt(json['reviewCount']),
      verificationStatus:
          VerificationStatusX.fromWire(json['verificationStatus'] as String?),
      schoolLevel: SchoolLevelX.fromWire(json['schoolLevel'] as String?),
      facilityImages: imgs
          .whereType<Map>()
          .map((m) => FacilityImage.fromJson(m.cast<String, dynamic>()))
          .toList(),
      followerCount: coerceInt(json['followerCount']),
      distanceKm: coerceDouble(json['distanceKm']),
    );
  }
}

class Pagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const Pagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v, int fallback) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }
    return Pagination(
      total: parseInt(json['total'], 0),
      page: parseInt(json['page'], 1),
      limit: parseInt(json['limit'], 10),
      totalPages: parseInt(json['totalPages'], 1),
    );
  }
}

class SchoolsPage {
  final List<School> items;
  final Pagination meta;
  const SchoolsPage(this.items, this.meta);
}

/// Filters for `GET /api/schools`. Mirrors `listSchoolsQuerySchema` on the
/// backend. `near` is a "lat,lng" string when set; we keep it untyped here
/// to match the wire format.
class SchoolListFilters {
  final String? search;
  final Curriculum? curriculum;
  final num? minFee;
  final num? maxFee;
  final String? near;
  final num? radiusKm;
  // Phase 11 additions.
  final num? minRating;
  final SchoolLevel? schoolLevel;
  final int page;
  final int limit;

  const SchoolListFilters({
    this.search,
    this.curriculum,
    this.minFee,
    this.maxFee,
    this.near,
    this.radiusKm,
    this.minRating,
    this.schoolLevel,
    this.page = 1,
    this.limit = 10,
  });

  SchoolListFilters copyWith({
    Object? search = _sentinel,
    Object? curriculum = _sentinel,
    Object? minFee = _sentinel,
    Object? maxFee = _sentinel,
    Object? near = _sentinel,
    Object? radiusKm = _sentinel,
    Object? minRating = _sentinel,
    Object? schoolLevel = _sentinel,
    int? page,
    int? limit,
  }) {
    return SchoolListFilters(
      search: identical(search, _sentinel) ? this.search : search as String?,
      curriculum: identical(curriculum, _sentinel)
          ? this.curriculum
          : curriculum as Curriculum?,
      minFee: identical(minFee, _sentinel) ? this.minFee : minFee as num?,
      maxFee: identical(maxFee, _sentinel) ? this.maxFee : maxFee as num?,
      near: identical(near, _sentinel) ? this.near : near as String?,
      radiusKm:
          identical(radiusKm, _sentinel) ? this.radiusKm : radiusKm as num?,
      minRating: identical(minRating, _sentinel)
          ? this.minRating
          : minRating as num?,
      schoolLevel: identical(schoolLevel, _sentinel)
          ? this.schoolLevel
          : schoolLevel as SchoolLevel?,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  Map<String, dynamic> toQueryParams() {
    return {
      if (search != null && search!.isNotEmpty) 'search': search,
      if (curriculum != null) 'curriculum': curriculum!.toWire(),
      if (minFee != null) 'minFee': minFee.toString(),
      if (maxFee != null) 'maxFee': maxFee.toString(),
      if (near != null && near!.isNotEmpty) 'near': near,
      if (radiusKm != null) 'radiusKm': radiusKm.toString(),
      if (minRating != null) 'minRating': minRating.toString(),
      if (schoolLevel != null) 'schoolLevel': schoolLevel!.toWire(),
      'page': page.toString(),
      'limit': limit.toString(),
    };
  }
}

const _sentinel = Object();

/// One row in `GET /api/recommendations` — backend bolts a `score` and
/// `breakdown` map onto each school.
class Recommendation {
  final School school;
  final num score;
  final Map<String, num> breakdown;

  const Recommendation({
    required this.school,
    required this.score,
    required this.breakdown,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    num parseNum(dynamic v, num fallback) {
      if (v is num) return v;
      if (v is String) return num.tryParse(v) ?? fallback;
      return fallback;
    }
    final raw = (json['breakdown'] as Map?) ?? const {};
    final bd = <String, num>{};
    raw.forEach((k, v) {
      bd[k.toString()] = parseNum(v, 0);
    });
    return Recommendation(
      school: School.fromJson(json),
      score: parseNum(json['score'], 0),
      breakdown: bd,
    );
  }
}
