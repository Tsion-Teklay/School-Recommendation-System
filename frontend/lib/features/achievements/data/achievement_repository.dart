import 'package:dio/dio.dart';  
import '../../../core/api_client.dart';  
import '../../auth/data/auth_repository.dart' show ApiException;  
import 'achievement_dtos.dart';  
import 'package:flutter_riverpod/flutter_riverpod.dart';
  
class AchievementRepository {  
  final Dio _dio;  
  
  AchievementRepository(this._dio);  
  
  // Achievement methods  
  Future<Achievement> createAchievement({  
    required int schoolId,  
    required String title,  
    String? description,  
    required String tier,  
    required int year,  
    List<String>? documents,  
  }) async {  
    final data = <String, dynamic>{
      'schoolId': schoolId,
      'title': title,
      'tier': tier,
      'year': year,
    };
    if (description != null) {
      data['description'] = description;
    }
    if (documents != null) {
      data['documents'] = documents;
    }
    final res = await _dio.post('/api/achievements', data: data);  
    if (res.statusCode != 201) throw _toApiException(res);  
    return Achievement.fromJson(res.data as Map<String, dynamic>);  
  }  
  
  Future<List<Achievement>> getSchoolAchievements(int schoolId) async {  
    final res = await _dio.get('/api/achievements/school/$schoolId');  
    if (res.statusCode != 200) throw _toApiException(res);  
    final List<dynamic> data = res.data as List<dynamic>;  
    return data.map((e) => Achievement.fromJson(e as Map<String, dynamic>)).toList();  
  }  

  Future<List<Achievement>> getPendingAchievements() async {  
  final res = await _dio.get('/api/achievements/pending');  
  if (res.statusCode != 200) throw _toApiException(res);  
  final List<dynamic> data = res.data as List<dynamic>;  
  return data.map((e) => Achievement.fromJson(e as Map<String, dynamic>)).toList();  
}
  
  Future<Achievement?> getById(int id) async {  
    final res = await _dio.get('/api/achievements/$id');  
    if (res.statusCode != 200) throw _toApiException(res);  
    if (res.data == null) return null;  
    return Achievement.fromJson(res.data as Map<String, dynamic>);  
  }  
  
  Future<Achievement> update({  
    required int id,  
    String? title,  
    String? description,  
    String? tier,  
    int? year,  
  }) async {  
    final data = <String, dynamic>{};  
    if (title != null) data['title'] = title;  
    if (description != null) data['description'] = description;  
    if (tier != null) data['tier'] = tier;  
    if (year != null) data['year'] = year;  
  
    final res = await _dio.put('/api/achievements/$id', data: data);  
    if (res.statusCode != 200) throw _toApiException(res);  
    return Achievement.fromJson(res.data as Map<String, dynamic>);  
  }  
  
  Future<void> delete(int id) async {  
    final res = await _dio.delete('/api/achievements/$id');  
    if (res.statusCode != 200) throw _toApiException(res);  
  }  

  Future<Achievement> reviewAchievement({  
  required int id,  
  required String status,  
  String? reviewNotes,  
}) async {
  final data = <String, dynamic>{
    'status': status,
  };
  if (reviewNotes != null) {
    data['reviewNotes'] = reviewNotes;
  }
  final res = await _dio.post('/api/achievements/$id/review', data: data);  
  if (res.statusCode != 200) throw _toApiException(res);  
  return Achievement.fromJson(res.data as Map<String, dynamic>);  
}
  
  // Staff breakdown methods  
  Future<StaffBreakdown> createStaffBreakdown({  
    required int schoolId,  
    required String educationLevel,  
    required int count,  
  }) async {  
    final res = await _dio.post('/api/staff-breakdown', data: {  
      'schoolId': schoolId,  
      'educationLevel': educationLevel,  
      'count': count,  
    });  
    if (res.statusCode != 201) throw _toApiException(res);  
    return StaffBreakdown.fromJson(res.data as Map<String, dynamic>);  
  }  
  
  Future<List<StaffBreakdown>> getSchoolStaffBreakdown(int schoolId) async {  
    final res = await _dio.get('/api/staff-breakdown/school/$schoolId');  
    if (res.statusCode != 200) throw _toApiException(res);  
    final List<dynamic> data = res.data as List<dynamic>;  
    return data.map((e) => StaffBreakdown.fromJson(e as Map<String, dynamic>)).toList();  
  }  
  
  Future<StaffBreakdown> updateStaffBreakdown({  
    required int id,  
    required int count,  
  }) async {  
    final res = await _dio.put('/api/staff-breakdown/$id', data: { 'count': count });  
    if (res.statusCode != 200) throw _toApiException(res);  
    return StaffBreakdown.fromJson(res.data as Map<String, dynamic>);  
  }  
  
  Future<void> deleteStaffBreakdown(int id) async {  
    final res = await _dio.delete('/api/staff-breakdown/$id');  
    if (res.statusCode != 200) throw _toApiException(res);  
  }  
  
  ApiException _toApiException(Response res) {
  final data = res.data;
  if (data is Map) {
    final msg = (data['error'] ?? data['message'])?.toString() ?? 'An error occurred';
    final code = data['code']?.toString();
    final details = data['details'] as List<dynamic>?;
    return ApiException(msg, statusCode: res.statusCode, code: code, details: details?.cast<Map<String, dynamic>>());
  }
  return ApiException('An error occurred (${res.statusCode})', statusCode: res.statusCode);
}  
}  
  
final achievementRepositoryProvider =
    Provider<AchievementRepository>((ref) {
  return AchievementRepository(
    ref.watch(apiClientProvider).dio,
  );
});