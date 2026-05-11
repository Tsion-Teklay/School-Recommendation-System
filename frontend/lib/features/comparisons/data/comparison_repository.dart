import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../auth/data/auth_repository.dart';
import 'comparison_dtos.dart';

class ComparisonRepository {
  final Dio _dio;
  ComparisonRepository(this._dio);

  Future<List<Comparison>> listMine() async {
    final res = await _dio.get('/api/comparisons');
    if (res.statusCode != 200) throw _toApiException(res);
    final body = res.data as Map<String, dynamic>;
    return (body['data'] as List)
        .cast<Map<String, dynamic>>()
        .map(Comparison.fromJson)
        .toList();
  }

  Future<Comparison> create(List<int> schoolIds, {List<String>? metrics}) async {
    final res = await _dio.post('/api/comparisons', data: {
      'schoolIds': schoolIds,
      if (metrics != null) 'metrics': metrics,
    });
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw _toApiException(res);
    }
    final body = res.data as Map<String, dynamic>;
    final raw = (body['comparison'] ?? body['data'] ?? body)
        as Map<String, dynamic>;
    return Comparison.fromJson(raw);
  }

  Future<Comparison> getById(int id) async {
    final res = await _dio.get('/api/comparisons/$id');
    if (res.statusCode != 200) throw _toApiException(res);
    final body = res.data as Map<String, dynamic>;
    final raw = (body['comparison'] ?? body['data'] ?? body)
        as Map<String, dynamic>;
    return Comparison.fromJson(raw);
  }

  Future<void> delete(int id) async {
    final res = await _dio.delete('/api/comparisons/$id');
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

final comparisonRepositoryProvider = Provider<ComparisonRepository>((ref) {
  return ComparisonRepository(ref.watch(apiClientProvider).dio);
});
