import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../../schools/data/school_dtos.dart';
import '../../schools/data/school_repository.dart';

class RecommendationsState {
  final List<Recommendation> items;
  final Map<String, dynamic> criteria;
  final bool loading;
  final String? error;

  const RecommendationsState({
    required this.items,
    required this.criteria,
    required this.loading,
    required this.error,
  });

  RecommendationsState copyWith({
    List<Recommendation>? items,
    Map<String, dynamic>? criteria,
    bool? loading,
    Object? error = _sentinel,
  }) {
    return RecommendationsState(
      items: items ?? this.items,
      criteria: criteria ?? this.criteria,
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }
}

const _sentinel = Object();

class RecommendationsController extends ChangeNotifier {
  final SchoolRepository _repo;
  RecommendationsController(this._repo) {
    refresh();
  }

  RecommendationsState _state = const RecommendationsState(
    items: [],
    criteria: {},
    loading: true,
    error: null,
  );
  RecommendationsState get state => _state;

  bool _disposed = false;
  void _set(RecommendationsState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> refresh({Curriculum? curriculum, num? maxFee}) async {
    _set(_state.copyWith(loading: true, error: null));
    try {
      final result =
          await _repo.recommend(curriculum: curriculum, maxFee: maxFee);
      _set(_state.copyWith(
        items: result.items,
        criteria: result.criteria,
        loading: false,
        error: null,
      ));
    } on ApiException catch (e) {
      _set(_state.copyWith(loading: false, error: e.message));
    } catch (e) {
      _set(_state.copyWith(loading: false, error: e.toString()));
    }
  }
}

final recommendationsControllerProvider =
    ChangeNotifierProvider.autoDispose<RecommendationsController>((ref) {
  return RecommendationsController(ref.watch(schoolRepositoryProvider));
});
