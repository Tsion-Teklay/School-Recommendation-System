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

  Future<School> getById(int id) async {
    final res = await _dio.get('/api/schools/$id');
    if (res.statusCode != 200) throw _toApiException(res);
    final body = res.data as Map<String, dynamic>;
    return School.fromJson(body['school'] as Map<String, dynamic>);
  }

  /// Returns the recommendations + the criteria the backend used so the UI
  /// can show the "based on your preferences (curriculum=LOCAL, max fee
  /// 60,000…)" subtitle.
  Future<({List<Recommendation> items, Map<String, dynamic> criteria})>
      recommend({Curriculum? curriculum, num? maxFee}) async {
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
    return (items: items, criteria: criteria);
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
    final raw = (body['image'] ?? body['facilityImage']) as Map<String, dynamic>?;
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
