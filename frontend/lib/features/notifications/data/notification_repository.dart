import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../auth/data/auth_repository.dart';
import 'notification_dtos.dart';

/// Thin HTTP layer for `/api/notifications`. Mirrors the same shape as
/// SchoolRepository (one method per route, no caching).
class NotificationRepository {
  final Dio _dio;
  NotificationRepository(this._dio);

  Future<({List<AppNotification> items, int total, int page, int totalPages})>
      list({int page = 1, int limit = 20, bool unreadOnly = false}) async {
    final res = await _dio.get(
      '/api/notifications',
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        if (unreadOnly) 'unread': 'true',
      },
    );
    if (res.statusCode != 200) throw _toApiException(res);
    final body = res.data as Map<String, dynamic>;
    final items = (body['data'] as List)
        .cast<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
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

  Future<void> markRead(int id) async {
    final res = await _dio.put('/api/notifications/$id/read');
    if (res.statusCode != 200) throw _toApiException(res);
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

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(apiClientProvider).dio);
});
