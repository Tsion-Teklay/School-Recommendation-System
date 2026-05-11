import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../auth/data/auth_repository.dart';
import 'forum_dtos.dart';

class ForumRepository {
  final Dio _dio;
  ForumRepository(this._dio);

  Future<({List<ForumPost> items, int page, int totalPages, int total})>
      list({int page = 1, int limit = 20}) async {
    final res = await _dio.get(
      '/api/forum',
      queryParameters: {'page': page.toString(), 'limit': limit.toString()},
    );
    if (res.statusCode != 200) throw _toApiException(res);
    final body = res.data as Map<String, dynamic>;
    final items = (body['data'] as List)
        .cast<Map<String, dynamic>>()
        .map(ForumPost.fromJson)
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

  Future<ForumPost> getById(int id) async {
    final res = await _dio.get('/api/forum/$id');
    if (res.statusCode != 200) throw _toApiException(res);
    final body = res.data as Map<String, dynamic>;
    return ForumPost.fromJson(body['post'] as Map<String, dynamic>);
  }

  Future<ForumPost> create(String content) async {
    final res = await _dio.post('/api/forum', data: {'content': content});
    if (res.statusCode != 201) throw _toApiException(res);
    final body = res.data as Map<String, dynamic>;
    return ForumPost.fromJson(body['post'] as Map<String, dynamic>);
  }

  Future<ForumPost> reply(int parentId, String content) async {
    final res = await _dio.post(
      '/api/forum/$parentId/replies',
      data: {'content': content},
    );
    if (res.statusCode != 201) throw _toApiException(res);
    final body = res.data as Map<String, dynamic>;
    return ForumPost.fromJson(body['post'] as Map<String, dynamic>);
  }

  Future<ForumPost> update(int id, String content) async {
    final res = await _dio.put('/api/forum/$id', data: {'content': content});
    if (res.statusCode != 200) throw _toApiException(res);
    final body = res.data as Map<String, dynamic>;
    return ForumPost.fromJson(body['post'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    final res = await _dio.delete('/api/forum/$id');
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

final forumRepositoryProvider = Provider<ForumRepository>((ref) {
  return ForumRepository(ref.watch(apiClientProvider).dio);
});
