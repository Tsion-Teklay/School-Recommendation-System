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
    required this.followerCount,
    required this.distanceKm,
  });

  factory School.fromJson(Map<String, dynamic> json) {
    double? coerceDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return School(
      id: (json['id'] as num).toInt(),
      schoolName: json['schoolName'] as String,
      address: (json['address'] ?? '') as String,
      contactEmail: (json['contactEmail'] ?? '') as String,
      contactPhone: json['contactPhone'] as String?,
      curriculum: CurriculumX.fromWire(json['curriculum'] as String),
      tuitionFee: (json['tuitionFee'] as num?) ?? 0,
      facilities: json['facilities'] as String?,
      latitude: coerceDouble(json['latitude']),
      longitude: coerceDouble(json['longitude']),
      rating: json['rating'] as num?,
      reviewCount: (json['reviewCount'] as num?)?.toInt(),
      verificationStatus:
          VerificationStatusX.fromWire(json['verificationStatus'] as String?),
      followerCount: (json['followerCount'] as num?)?.toInt(),
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

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
        total: (json['total'] as num).toInt(),
        page: (json['page'] as num).toInt(),
        limit: (json['limit'] as num).toInt(),
        totalPages: (json['totalPages'] as num).toInt(),
      );
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
  final int page;
  final int limit;

  const SchoolListFilters({
    this.search,
    this.curriculum,
    this.minFee,
    this.maxFee,
    this.near,
    this.radiusKm,
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
    final raw = (json['breakdown'] as Map?) ?? const {};
    final bd = <String, num>{};
    raw.forEach((k, v) {
      if (v is num) bd[k.toString()] = v;
    });
    return Recommendation(
      school: School.fromJson(json),
      score: (json['score'] as num?) ?? 0,
      breakdown: bd,
    );
  }
}
