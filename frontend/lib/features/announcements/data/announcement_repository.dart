import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../auth/data/auth_repository.dart';
import 'announcement_dtos.dart';

class AnnouncementRepository {
  final Dio _dio;
  AnnouncementRepository(this._dio);

  Future<({List<Announcement> items, int page, int totalPages, int total})>
      list({
    int page = 1,
    int limit = 20,
    AnnouncementCategory? category,
    UrgencyLevel? urgencyLevel,
    int? schoolId,
  }) async {
    final res = await _dio.get(
      '/api/announcements',
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        if (category != null) 'category': category.toWire(),
        if (urgencyLevel != null) 'urgencyLevel': urgencyLevel.toWire(),
        if (schoolId != null) 'schoolId': schoolId.toString(),
      },
    );
    if (res.statusCode != 200) throw _toApiException(res);
    final body = res.data as Map<String, dynamic>;
    final items = (body['data'] as List)
        .cast<Map<String, dynamic>>()
        .map(Announcement.fromJson)
        .toList();
    final meta = (body['meta'] as Map?)?.cast<String, dynamic>() ?? {};
    int parseInt(dynamic v, int fallback) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }
    return (
      items: items,
      total: parseInt(meta['total'], 0),
      page: parseInt(meta['page'], page),
      totalPages: parseInt(meta['totalPages'], 1),
    );
  }

  /// School admin path.
  Future<Announcement> createForSchool(AnnouncementInput input) async {
    final res = await _dio.post(
      '/api/announcements/school',
      data: input.toJson(),
    );
    if (res.statusCode != 201) throw _toApiException(res);
    return Announcement.fromJson(
      (res.data as Map<String, dynamic>)['announcement']
          as Map<String, dynamic>,
    );
  }

  /// MoE officer path.
  Future<Announcement> createForMoe(AnnouncementInput input) async {
    final res = await _dio.post(
      '/api/announcements/moe',
      data: input.toJson(),
    );
    if (res.statusCode != 201) throw _toApiException(res);
    return Announcement.fromJson(
      (res.data as Map<String, dynamic>)['announcement']
          as Map<String, dynamic>,
    );
  }

  Future<void> delete(int id) async {
    final res = await _dio.delete('/api/announcements/$id');
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw _toApiException(res);
    }
  }
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

final announcementRepositoryProvider =
    Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepository(ref.watch(apiClientProvider).dio);
});
