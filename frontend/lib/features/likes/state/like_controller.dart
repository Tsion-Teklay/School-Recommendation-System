import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../data/like_dtos.dart';
import '../data/like_repository.dart';

class LikeController extends ChangeNotifier {
  final LikeRepository _repo;

  // Cache for like status and counts
  final Map<String, bool> _likeStatus = {};
  final Map<String, int> _likeCounts = {};

  LikeController(this._repo);

  /// Get like status for a target
  bool isLiked(LikeTargetType type, int id) {
    final key = _getKey(type, id);
    return _likeStatus[key] ?? false;
  }

  /// Get like count for a target
  int getLikeCount(LikeTargetType type, int id) {
    final key = _getKey(type, id);
    return _likeCounts[key] ?? 0;
  }

  /// Toggle like status
  Future<void> toggleLike(LikeTargetType type, int id) async {
    final key = _getKey(type, id);
    final currentStatus = _likeStatus[key] ?? false;
    final currentCount = _likeCounts[key] ?? 0;

    // Optimistic update
    _likeStatus[key] = !currentStatus;
    _likeCounts[key] = currentCount + (currentStatus ? -1 : 1);
    notifyListeners();

    try {
      await _repo.toggleLike(type, id);

      // Refresh the actual count after toggle
      final countResponse = await _repo.getLikeCount(type, id);
      _likeCounts[key] = countResponse.count;

      // Refresh the actual status after toggle
      final statusResponse = await _repo.getUserLikeStatus(type, id);
      _likeStatus[key] = statusResponse.liked;

      notifyListeners();
    } catch (e) {
      // Revert optimistic update on error
      _likeStatus[key] = currentStatus;
      _likeCounts[key] = currentCount;
      notifyListeners();

      debugPrint('Error toggling like: $e');
    }
  }

  /// Refresh like data for a specific target
  Future<void> refreshLikeData(LikeTargetType type, int id) async {
    final key = _getKey(type, id);

    try {
      final responses = await Future.wait([
        _repo.getLikeCount(type, id),
        _repo.getUserLikeStatus(type, id),
      ]);

      final countResponse = responses[0] as LikeCountResponse;
      final statusResponse = responses[1] as LikeToggleResponse;

      _likeCounts[key] = countResponse.count;
      _likeStatus[key] = statusResponse.liked;
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing like data: $e');
    }
  }

  /// Generate a unique key for caching
  String _getKey(LikeTargetType type, int id) {
    return '${type.name}_$id';
  }
}

final likeControllerProvider = ChangeNotifierProvider<LikeController>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LikeController(LikeRepository(apiClient));
});
