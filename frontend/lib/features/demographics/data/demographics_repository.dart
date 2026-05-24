import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import 'demographics_dtos.dart';
import '../../auth/data/auth_repository.dart' show ApiException;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DemographicsRepository {
  final Dio _dio;

  DemographicsRepository(this._dio);

  Future<SchoolDemographics> create({
    required int schoolId,
    required int academicYear,
    required int totalStudents,
    required int girlsCount,
    required int boysCount,
    required double passingRate,
    required double nationalExamScore,
  }) async {
    final res = await _dio.post('/api/demographics', data: {
      'schoolId': schoolId,
      'academicYear': academicYear,
      'totalStudents': totalStudents,
      'girlsCount': girlsCount,
      'boysCount': boysCount,
      'passingRate': passingRate,
      'nationalExamScore': nationalExamScore,
    });
    if (res.statusCode != 201) throw _toApiException(res);
    return SchoolDemographics.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<SchoolDemographics>> getBySchool(int schoolId) async {
    final res = await _dio.get('/api/demographics/school/$schoolId');
    if (res.statusCode != 200) throw _toApiException(res);

    // res.data can be null or an unexpected shape if the server fails silently;
    // default to an empty list to avoid a hard cast crash.
    final List<dynamic> data =
        res.data is List ? res.data as List<dynamic> : [];

    return data
        .map((e) => SchoolDemographics.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SchoolDemographics?> getByYear(int schoolId, int academicYear) async {
    final res = await _dio.get('/api/demographics/school/$schoolId/year/$academicYear');
    if (res.statusCode != 200) throw _toApiException(res);
    if (res.data == null) return null;
    return SchoolDemographics.fromJson(res.data as Map<String, dynamic>);
  }

  Future<SchoolDemographics> update({
    required int id,
    int? totalStudents,
    int? girlsCount,
    int? boysCount,
    double? passingRate,
    double? nationalExamScore,
  }) async {
    final data = <String, dynamic>{};
    if (totalStudents != null) data['totalStudents'] = totalStudents;
    if (girlsCount != null) data['girlsCount'] = girlsCount;
    if (boysCount != null) data['boysCount'] = boysCount;
    if (passingRate != null) data['passingRate'] = passingRate;
    if (nationalExamScore != null) data['nationalExamScore'] = nationalExamScore;

    final res = await _dio.put('/api/demographics/$id', data: data);
    if (res.statusCode != 200) throw _toApiException(res);
    return SchoolDemographics.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    final res = await _dio.delete('/api/demographics/$id');
    if (res.statusCode != 200) throw _toApiException(res);
  }

  ApiException _toApiException(Response res) {
    final errorMessage = res.data is Map
        ? (res.data['error'] ?? res.data['message'] ?? 'An error occurred')
        : 'An error occurred';

    return ApiException(
      errorMessage,
      statusCode: res.statusCode,
      code: res.data is Map ? res.data['code'] : null,
    );
  }
}

final demographicsRepositoryProvider = Provider<DemographicsRepository>((ref) {
  return DemographicsRepository(ref.watch(apiClientProvider).dio);
});