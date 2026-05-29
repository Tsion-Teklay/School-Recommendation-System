import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../auth/data/auth_repository.dart';
import 'announcement_dtos.dart';
import 'comment_dtos.dart';

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
    bool? followedOnly,
    PublisherType? publisherType,
  }) async {
    final res = await _dio.get(
      '/api/announcements',
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        if (category != null) 'category': category.toWire(),
        if (urgencyLevel != null) 'urgencyLevel': urgencyLevel.toWire(),
        if (schoolId != null) 'schoolId': schoolId.toString(),
        if (followedOnly == true) 'followedOnly': 'true',
        if (publisherType != null) 'publisherType': publisherType.toWire(),
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

  Future<Announcement> update(int id, AnnouncementInput input) async {
    final res = await _dio.put(
      '/api/announcements/$id',
      data: input.toJson(),
    );
    if (res.statusCode != 200) throw _toApiException(res);
    return Announcement.fromJson(
      (res.data as Map<String, dynamic>)['announcement']
          as Map<String, dynamic>,
    );
  }

  /// Phase 11 — fetch a single announcement (used by the deep-linkable
  /// detail screen). Returns the announcement with `school` summary
  /// joined and `imgUrl` populated when present.
  Future<Announcement> getById(int id) async {
    final res = await _dio.get('/api/announcements/$id');
    if (res.statusCode != 200) throw _toApiException(res);
    final body = res.data as Map<String, dynamic>;
    return Announcement.fromJson(
      body['announcement'] as Map<String, dynamic>,
    );
  }

  /// Phase 11 — attach (or replace) the banner image on an existing
  /// announcement. Only the original publisher (school admin / MoE
  /// officer) may call this.
  Future<Announcement> uploadImage({
    required int id,
    required String filename,
    required Uint8List bytes,
  }) async {
    final form = FormData();
    form.files.add(MapEntry(
      'image',
      MultipartFile.fromBytes(bytes, filename: filename),
    ));
    final res = await _dio.post(
      '/api/announcements/$id/image',
      data: form,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw _toApiException(res);
    }
    return Announcement.fromJson(
      (res.data as Map<String, dynamic>)['announcement']
          as Map<String, dynamic>,
    );
  }

  /// Phase 11 — clear the banner image from an announcement.
  Future<void> deleteImage(int id) async {
    final res = await _dio.delete('/api/announcements/$id/image');
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw _toApiException(res);
    }
  }

  Future<List<Comment>> getAnnouncementComments(int id) async {
    final res = await _dio.get('/api/forum/announcement/$id');
    if (res.statusCode != 200) throw _toApiException(res);
    final body = res.data as Map<String, dynamic>;
    return (body['data'] as List)
        .cast<Map<String, dynamic>>()
        .map((c) => Comment.fromJson(c))
        .toList();
  }

  Future<void> postAnnouncementComment(int announcementId, String content) async {
    final res = await _dio.post(
      '/api/forum/announcement/$announcementId',
      data: {'content': content},
    );
    if (res.statusCode != 201) throw _toApiException(res);
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

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepository(ref.watch(apiClientProvider).dio);
});
