import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../auth/data/auth_repository.dart' show ApiException;
import 'preference_dtos.dart';
import '../../schools/data/school_dtos.dart';

/// Thin wrapper around the preferences endpoints. Mirrors the
/// pattern in AuthRepository — one method per route, no caching, surfaces
/// backend `error`/`code` envelopes via ApiException.
class PreferenceRepository {
  final Dio _dio;
  PreferenceRepository(this._dio);

  Future<ParentPreferences> getMine() async {
    final res = await _dio.get('/api/preferences/me');
    if (res.statusCode != 200) {
      throw _toApiException(res);
    }
    final body = res.data as Map<String, dynamic>;
    final raw = body['preference'] as Map<String, dynamic>?;
    if (raw == null) return ParentPreferences.empty();
    return ParentPreferences.fromJson(raw);
  }

  /// Upserts both the home-pin (on Parent) and the recommender criteria (on
  /// Preference). The backend rejects the call with 400 when this is a
  /// first-time write and the home-pin is missing — surface that as a
  /// readable ApiException.
  Future<ParentPreferences> save({
    double? minBudget,
    double? maxBudget,
    PreferredCurriculum? curriculum,
    int? distanceKm,
    SchoolLevel? schoolLevel,
    SchoolType? schoolType,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{
      if (minBudget != null) 'minBudget': minBudget,
      if (maxBudget != null) 'maxBudget': maxBudget,
      if (curriculum != null) 'curriculum': curriculum.toWire(),
      if (distanceKm != null) 'distance': distanceKm,
      if (schoolLevel != null) 'schoolLevel': schoolLevel.toWire(),
      if (schoolType != null) 'schoolType': schoolType.toWire(),
      if (address != null && address.isNotEmpty) 'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
    final res = await _dio.post('/api/preferences', data: body);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw _toApiException(res);
    }
    // POST returns the Preference row only — refetch the merged shape so the
    // caller's local state stays consistent with what /me would return.
    return getMine();
  }

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
}

final preferenceRepositoryProvider = Provider<PreferenceRepository>((ref) {
  return PreferenceRepository(ref.watch(apiClientProvider).dio);
});
