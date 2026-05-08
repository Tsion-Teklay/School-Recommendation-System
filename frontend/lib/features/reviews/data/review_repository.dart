import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../auth/data/auth_repository.dart';
import 'review_dtos.dart';

class ReviewRepository {
  final Dio _dio;
  ReviewRepository(this._dio);

  Future<List<Review>> listForSchool(int schoolId) async {
    final res = await _dio.get('/api/reviews/school/$schoolId');
    if (res.statusCode != 200) throw _toApiException(res);
    final body = res.data as Map<String, dynamic>;
    return (body['data'] as List)
        .cast<Map<String, dynamic>>()
        .map(Review.fromJson)
        .toList();
  }

  Future<Review> create(int schoolId, ReviewInput input) async {
    final res = await _dio.post(
      '/api/reviews/$schoolId',
      data: input.toJson(),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw _toApiException(res);
    }
    final body = res.data as Map<String, dynamic>;
    return Review.fromJson(body['review'] as Map<String, dynamic>);
  }

  Future<Review> update(int reviewId, ReviewInput input) async {
    final res = await _dio.put(
      '/api/reviews/$reviewId',
      data: input.toJson(),
    );
    if (res.statusCode != 200) throw _toApiException(res);
    final body = res.data as Map<String, dynamic>;
    return Review.fromJson(body['review'] as Map<String, dynamic>);
  }

  Future<void> delete(int reviewId) async {
    final res = await _dio.delete('/api/reviews/$reviewId');
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

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.watch(apiClientProvider).dio);
});
