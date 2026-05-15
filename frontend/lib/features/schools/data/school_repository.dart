import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../auth/data/auth_repository.dart';
import 'school_dtos.dart';

/// Schools, recommendations, follows. One method per backend route. We don't
/// cache here — Riverpod controllers (next directory over) own state and
/// invalidation; the repository stays a thin HTTP layer.
class SchoolRepository {
  final Dio _dio;
  SchoolRepository(this._dio);

  Future<SchoolsPage> list(SchoolListFilters filters) async {
    final res = await _dio.get(
      '/api/schools',
      queryParameters: filters.toQueryParams(),
    );
    if (res.statusCode != 200) throw _toApiException(res);
    final body = res.data as Map<String, dynamic>;
    final data = (body['data'] as List)
        .cast<Map<String, dynamic>>()
        .map(School.fromJson)
        .toList();
    return SchoolsPage(
      data,
      Pagination.fromJson(body['meta'] as Map<String, dynamic>),
    );
  }

  Future<void> sendRecommendationFeedback({
    required int historyId,
    required String result,
    required int schoolId,
  }) async {
    final res = await _dio.post(
      '/api/recommendations/$historyId/feedback',
      data: {
        'result': result,
        'schoolId': schoolId,
      },
    );
    if (res.statusCode != 200) throw _toApiException(res);
  }

  Future<School> getById(int id) async {
    final res = await _dio.get('/api/schools/$id');
    if (res.statusCode != 200) throw _toApiException(res);
    final body = res.data as Map<String, dynamic>;
    return School.fromJson(body['school'] as Map<String, dynamic>);
  }

  Future<
      ({
        List<Recommendation> items,
        Map<String, dynamic> criteria,
        int? historyId
      })> recommend({Curriculum? curriculum, num? maxFee}) async {
    final res = await _dio.get(
      '/api/recommendations',
      queryParameters: {
        if (curriculum != null) 'curriculum': curriculum.toWire(),
        if (maxFee != null) 'maxFee': maxFee.toString(),
      },
    );
    if (res.statusCode != 200) throw _toApiException(res);
    final body = res.data as Map<String, dynamic>;
    final items = (body['data'] as List)
        .cast<Map<String, dynamic>>()
        .map(Recommendation.fromJson)
        .toList();
    final criteria = (body['criteria'] as Map?)?.cast<String, dynamic>() ?? {};
    final historyId = body['historyId'] as int?; // ADD THIS
    return (
      items: items,
      criteria: criteria,
      historyId: historyId
    ); // UPDATE RETURN TYPE
  }

  Future<void> follow(int schoolId) async {
    final res = await _dio.post('/api/schools/$schoolId/follow');
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw _toApiException(res);
    }
  }

  Future<void> unfollow(int schoolId) async {
    final res = await _dio.delete('/api/schools/$schoolId/follow');
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw _toApiException(res);
    }
  }

  /// Phase 11 — upload one facility image (PNG/JPEG/WebP, ≤ 10MB).
  /// School admin only. Returns the newly created FacilityImage row.
  Future<FacilityImage> uploadFacilityImage({
    required int schoolId,
    required String filename,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final form = FormData();
    form.files.add(MapEntry(
      'image',
      MultipartFile.fromBytes(bytes, filename: filename),
    ));
    final res = await _dio.post(
      '/api/schools/$schoolId/images',
      data: form,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw _toApiException(res);
    }
    final body = res.data as Map<String, dynamic>;
    // Backend controller wraps the new row as `{ message, image }`. The
    // older key `facilityImage` is tolerated for forward compatibility.
    final raw =
        (body['image'] ?? body['facilityImage']) as Map<String, dynamic>?;
    if (raw == null) {
      throw ApiException('Upload succeeded but response was empty',
          statusCode: res.statusCode);
    }
    return FacilityImage.fromJson(raw);
  }

  /// Phase 11 — delete a facility image by id. School admin only.
  Future<void> deleteFacilityImage({
    required int schoolId,
    required int imageId,
  }) async {
    final res = await _dio.delete('/api/schools/$schoolId/images/$imageId');
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw _toApiException(res);
    }
  }

  /// Returns the school IDs I follow. Used by the detail screen to
  /// initialise the follow toggle without a per-school round-trip.
  Future<Set<int>> myFollowedSchoolIds() async {
    final res = await _dio.get('/api/me/follows');
    if (res.statusCode != 200) throw _toApiException(res);
    final body = res.data as Map<String, dynamic>;
    final raw = (body['data'] as List).cast<Map<String, dynamic>>();
    return raw
        .map((row) {
          // Backend returns rows of { school: { id, ... } }; tolerate either
          // shape so a future flattening change doesn't break the frontend.
          if (row['school'] is Map) {
            return (row['school'] as Map)['id'] as num?;
          }
          return row['schoolId'] as num? ?? row['id'] as num?;
        })
        .whereType<num>()
        .map((n) => n.toInt())
        .toSet();
  }

  /// Create a new school. School admin only. Returns the newly created School.
  Future<School> create({
    required String schoolName,
    required String address,
    required String contactEmail,
    String? contactPhone,
    required Curriculum curriculum,
    SchoolLevel? schoolLevel,
    required num tuitionFee,
    String? facilities,
    double? latitude,
    double? longitude,
  }) async {
    final res = await _dio.post('/api/schools', data: {
      'schoolName': schoolName,
      'address': address,
      'contactEmail': contactEmail,
      if (contactPhone != null) 'contactPhone': contactPhone,
      'curriculum': curriculum.toWire(),
      if (schoolLevel != null) 'schoolLevel': schoolLevel.toWire(),
      'tuitionFee': tuitionFee,
      if (facilities != null) 'facilities': facilities,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
    if (res.statusCode != 201) throw _toApiException(res);
    final body = res.data as Map<String, dynamic>;
    return School.fromJson(body['school'] as Map<String, dynamic>);
  }

  /// Update a school. School admin only. Returns the updated School.
  Future<School> update({
    required int id,
    String? schoolName,
    String? address,
    String? contactEmail,
    String? contactPhone,
    Curriculum? curriculum,
    SchoolLevel? schoolLevel,
    num? tuitionFee,
    String? facilities,
    double? latitude,
    double? longitude,
  }) async {
    final data = <String, dynamic>{};
    if (schoolName != null) data['schoolName'] = schoolName;
    if (address != null) data['address'] = address;
    if (contactEmail != null) data['contactEmail'] = contactEmail;
    if (contactPhone != null) data['contactPhone'] = contactPhone;
    if (curriculum != null) data['curriculum'] = curriculum.toWire();
    if (schoolLevel != null) data['schoolLevel'] = schoolLevel.toWire();
    if (tuitionFee != null) data['tuitionFee'] = tuitionFee;
    if (facilities != null) data['facilities'] = facilities;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;

    final res = await _dio.put('/api/schools/$id', data: data);
    if (res.statusCode != 200) throw _toApiException(res);
    final body = res.data as Map<String, dynamic>;
    return School.fromJson(body['school'] as Map<String, dynamic>);
  }

  /// Get paginated list of schools the current parent follows.
  Future<SchoolsPage> myFollowedSchools({int limit = 50, int page = 1}) async {
    final res = await _dio.get(
      '/api/me/follows',
      queryParameters: {'limit': limit, 'page': page},
    );
    if (res.statusCode != 200) throw _toApiException(res);
    final body = res.data as Map<String, dynamic>;
    final data = (body['data'] as List).cast<Map<String, dynamic>>().map((row) {
      // Backend returns { school: { id, ... } }
      final schoolData = row['school'] as Map<String, dynamic>;
      return School.fromJson(schoolData);
    }).toList();
    return SchoolsPage(
      data,
      Pagination.fromJson(body['meta'] as Map<String, dynamic>),
    );
  }
}

/// Re-export the ApiException builder from auth_repository so screens that
/// already catch ApiException don't need a second import path.
ApiException _toApiException(Response<dynamic> r) {
  final data = r.data;
  if (data is Map) {
    final msg =
        (data['error'] ?? data['message'])?.toString() ?? 'Request failed';
    final code = data['code']?.toString();
    return ApiException(msg, statusCode: r.statusCode, code: code);
  }
  return ApiException('Request failed (${r.statusCode})',
      statusCode: r.statusCode);
}

final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
  return SchoolRepository(ref.watch(apiClientProvider).dio);
});
