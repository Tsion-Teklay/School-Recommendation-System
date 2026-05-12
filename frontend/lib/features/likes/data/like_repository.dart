import '../../../core/api_client.dart';  
import 'like_dtos.dart';  
  
class LikeRepository {  
  final ApiClient _api;  
  
  LikeRepository(this._api);  
  
  Future<LikeToggleResponse> toggleLike(LikeTargetType type, int id) async {  
    final res = await _api.post('/api/likes/toggle', data: LikeToggleRequest(  
      targetType: type,  
      targetId: id,  
    ).toJson());  
    return LikeToggleResponse.fromJson(res.data);  
  }  
  
  Future<LikeCountResponse> getLikeCount(LikeTargetType type, int id) async {  
    final res = await _api.get('/api/likes/${type.name.toUpperCase()}/$id/count');  
    return LikeCountResponse.fromJson(res.data);  
  }  
  
  Future<LikeToggleResponse> getUserLikeStatus(LikeTargetType type, int id) async {  
    final res = await _api.get('/api/likes/${type.name.toUpperCase()}/$id/status');  
    return LikeToggleResponse.fromJson(res.data);  
  }  
} 

