import 'package:dio/dio.dart';  
import 'package:flutter_riverpod/flutter_riverpod.dart';  
  
import '../../../core/api_client.dart';  
import '../../auth/data/auth_repository.dart' show ApiException;  
import 'analytics_dtos.dart';  
import '../../demographics/data/demographics_dtos.dart';    
import '../../achievements/data/achievement_dtos.dart';    
  
class AnalyticsRepository {  
  final Dio _dio;  
  AnalyticsRepository(this._dio);  
  
  Future<Dashboard> dashboard() async {  
    final res = await _dio.get('/api/analytics/dashboard');  
    if (res.statusCode != 200) throw _toApiException(res);  
    final body = res.data as Map<String, dynamic>;  
    return Dashboard.fromJson(body);  
  }  
  
  /// Returns the raw CSV string. The screen layer is responsible for  
  /// triggering a download (web) or sharing (mobile).  
  Future<String> dashboardCsv() async {  
    final res = await _dio.get<dynamic>(  
      '/api/analytics/dashboard.csv',  
      options: Options(responseType: ResponseType.plain),  
    );  
    if (res.statusCode != 200) throw _toApiException(res);  
    return (res.data ?? '').toString();  
  }  
  
  Future<SchoolAnalytics> getSchoolAnalytics(int schoolId) async {    
    final res = await _dio.get('/api/analytics/schools/$schoolId');    
    if (res.statusCode != 200) throw _toApiException(res);    
    return SchoolAnalytics.fromJson(res.data as Map<String, dynamic>);    
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
  
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {    
  return AnalyticsRepository(ref.watch(apiClientProvider).dio);    
});