import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../auth/data/auth_repository.dart';
import 'report_dtos.dart';

class ReportRepository {
  final Dio _dio;
  ReportRepository(this._dio);

  Future<List<Report>> list({ReportStatus? status}) async {
    final res = await _dio.get(
      '/api/reports',
      queryParameters: {
        if (status != null) 'status': status.toWire(),
      },
    );
    if (res.statusCode != 200) throw _toApiException(res);
    final body = res.data as Map<String, dynamic>;
    final data = body['data'];
    final rows = data is Map ? (data['data'] as List? ?? []) : (data as List);
    return rows.cast<Map<String, dynamic>>().map(Report.fromJson).toList();
  }

  Future<Report> getById(int id) async {
    final res = await _dio.get('/api/reports/$id');
    if (res.statusCode != 200) throw _toApiException(res);
    final body = res.data as Map<String, dynamic>;
    return Report.fromJson(body['report'] as Map<String, dynamic>);
  }

  Future<Report> create(ReportInput input) async {
    final res = await _dio.post('/api/reports', data: input.toJson());
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw _toApiException(res);
    }
    final body = res.data as Map<String, dynamic>;
    return Report.fromJson(body['report'] as Map<String, dynamic>);
  }

  Future<void> takeAction(int reportId, ModeratorActionInput input) async {
    final res = await _dio.post(
      '/api/reports/$reportId/action',
      data: input.toJson(),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw _toApiException(res);
    }
  }

  Future<void> submitReport(ReportRequest request) async {
    final res = await _dio.post(
      '/api/reports',
      data: request.toJson(),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
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

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(apiClientProvider).dio);
});
