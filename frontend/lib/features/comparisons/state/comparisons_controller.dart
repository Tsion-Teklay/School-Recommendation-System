import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../data/comparison_dtos.dart';
import '../data/comparison_repository.dart';

class ComparisonsListState {
  final List<Comparison> items;
  final bool loading;
  final String? error;

  const ComparisonsListState({
    required this.items,
    required this.loading,
    required this.error,
  });

  ComparisonsListState copyWith({
    List<Comparison>? items,
    bool? loading,
    Object? error = _sentinel,
  }) {
    return ComparisonsListState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }
}

const _sentinel = Object();

class ComparisonsController extends ChangeNotifier {
  final ComparisonRepository _repo;
  ComparisonsController(this._repo) {
    refresh();
  }

  ComparisonsListState _state = const ComparisonsListState(
    items: [],
    loading: true,
    error: null,
  );
  ComparisonsListState get state => _state;

  bool _disposed = false;
  void _set(ComparisonsListState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> refresh() async {
    _set(_state.copyWith(loading: true, error: null));
    try {
      final items = await _repo.listMine();
      _set(_state.copyWith(items: items, loading: false, error: null));
    } on ApiException catch (e) {
      _set(_state.copyWith(loading: false, error: e.message));
    } catch (e) {
      _set(_state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<Comparison> create(List<int> schoolIds) async {
    final created = await _repo.create(schoolIds);
    // Optimistically prepend so the user sees their new comparison without
    // a second round-trip; refresh later if the saved view loads slowly.
    _set(_state.copyWith(items: [created, ..._state.items]));
    return created;
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    _set(_state.copyWith(
      items: _state.items.where((c) => c.id != id).toList(),
    ));
  }
}

final comparisonsControllerProvider =
    ChangeNotifierProvider.autoDispose<ComparisonsController>((ref) {
  return ComparisonsController(ref.watch(comparisonRepositoryProvider));
});
