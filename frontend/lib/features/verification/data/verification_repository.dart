import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../auth/data/auth_repository.dart';
import 'verification_dtos.dart';

/// Tiny holder for a file the user picked. Web uses `bytes`; native platforms
/// can also use `bytes` (we read the file into memory before submitting).
class PickedFile {
  final String filename;
  final Uint8List bytes;
  final String? contentType;
  const PickedFile({
    required this.filename,
    required this.bytes,
    this.contentType,
  });
}

class VerificationRepository {
  final Dio _dio;
  VerificationRepository(this._dio);

  /// Submit a verification request. The backend route is multipart and
  /// expects field `documents` per file plus an optional `notes` text field.
  Future<VerificationRequest> submit({
    required int schoolId,
    required List<PickedFile> documents,
    String? notes,
  }) async {
    final form = FormData();
    for (final f in documents) {
      form.files.add(MapEntry(
        'documents',
        MultipartFile.fromBytes(
          f.bytes,
          filename: f.filename,
        ),
      ));
    }
    if (notes != null && notes.isNotEmpty) {
      form.fields.add(MapEntry('notes', notes));
    }
    final res = await _dio.post(
      '/api/schools/$schoolId/verification-requests',
      data: form,
      options: Options(
        // Let Dio set the multipart Content-Type with boundary.
        headers: {'Content-Type': 'multipart/form-data'},
      ),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw _toApiException(res);
    }
    final body = res.data as Map<String, dynamic>;
    return VerificationRequest.fromJson(
      body['request'] as Map<String, dynamic>,
    );
  }

  Future<({List<VerificationRequest> items, int page, int totalPages, int total})>
      list({
    int page = 1,
    int limit = 20,
    VerificationRequestStatus? status,
  }) async {
    final res = await _dio.get(
      '/api/verification-requests',
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status.toWire(),
      },
    );
    if (res.statusCode != 200) throw _toApiException(res);
    final body = res.data as Map<String, dynamic>;
    final items = (body['data'] as List)
        .cast<Map<String, dynamic>>()
        .map(VerificationRequest.fromJson)
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

  Future<VerificationRequest> getById(int id) async {
    final res = await _dio.get('/api/verification-requests/$id');
    if (res.statusCode != 200) throw _toApiException(res);
    final body = res.data as Map<String, dynamic>;
    return VerificationRequest.fromJson(
      body['request'] as Map<String, dynamic>,
    );
  }

  /// MoE-only: approve or reject a request.
  Future<VerificationRequest> review({
    required int id,
    required VerificationRequestStatus status,
    String? reviewNotes,
  }) async {
    final res = await _dio.post(
      '/api/verification-requests/$id/review',
      data: {
        'status': status.toWire(),
        if (reviewNotes != null && reviewNotes.isNotEmpty)
          'reviewNotes': reviewNotes,
      },
    );
    if (res.statusCode != 200) throw _toApiException(res);
    final body = res.data as Map<String, dynamic>;
    return VerificationRequest.fromJson(
      body['request'] as Map<String, dynamic>,
    );
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

final verificationRepositoryProvider =
    Provider<VerificationRepository>((ref) {
  return VerificationRepository(ref.watch(apiClientProvider).dio);
});
