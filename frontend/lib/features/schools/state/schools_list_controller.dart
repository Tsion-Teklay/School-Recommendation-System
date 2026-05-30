import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/error_handler.dart';
import '../data/school_dtos.dart';
import '../data/school_repository.dart';

/// State for the schools browse screen.
///
/// We hand-roll a `ChangeNotifier` instead of `AsyncNotifier` so paginated
/// loading composes cleanly: `applyFilters` resets and refetches page 1,
/// `loadMore` appends the next page without disturbing what's on screen, and
/// every state field stays observable from a single `notifyListeners`.
class SchoolsListState {
  final SchoolListFilters filters;
  final List<School> items;
  final Pagination? meta;
  final bool initialLoading;
  final bool loadingMore;
  final String? error;

  const SchoolsListState({
    required this.filters,
    required this.items,
    required this.meta,
    required this.initialLoading,
    required this.loadingMore,
    required this.error,
  });

  SchoolsListState copyWith({
    SchoolListFilters? filters,
    List<School>? items,
    Pagination? meta,
    bool? initialLoading,
    bool? loadingMore,
    Object? error = _sentinel,
  }) {
    return SchoolsListState(
      filters: filters ?? this.filters,
      items: items ?? this.items,
      meta: meta ?? this.meta,
      initialLoading: initialLoading ?? this.initialLoading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  bool get hasMore {
    if (meta == null) return false;
    return meta!.page < meta!.totalPages;
  }
}

const _sentinel = Object();

class SchoolsListController extends ChangeNotifier {
  final SchoolRepository _repo;
  SchoolsListController(this._repo) {
    refresh();
  }

  SchoolsListState _state = const SchoolsListState(
    filters: SchoolListFilters(),
    items: [],
    meta: null,
    initialLoading: true,
    loadingMore: false,
    error: null,
  );
  SchoolsListState get state => _state;

  bool _disposed = false;
  void _set(SchoolsListState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Apply new filters and refetch page 1. We always reset paging on filter
  /// changes — silently keeping page=N from a stale filter set leads to
  /// "skip past the matches" bugs.
  Future<void> applyFilters(SchoolListFilters next) async {
    _set(_state.copyWith(
      filters: next.copyWith(page: 1),
      items: [],
      meta: null,
      initialLoading: true,
      loadingMore: false,
      error: null,
    ));
    await _fetchCurrent(append: false);
  }

  Future<void> refresh() async {
    _set(_state.copyWith(
      filters: _state.filters.copyWith(page: 1),
      items: [],
      meta: null,
      initialLoading: true,
      loadingMore: false,
      error: null,
    ));
    await _fetchCurrent(append: false);
  }

  Future<void> loadMore() async {
    if (!_state.hasMore || _state.loadingMore || _state.initialLoading) return;
    final nextPage = (_state.meta?.page ?? 1) + 1;
    _set(_state.copyWith(
      filters: _state.filters.copyWith(page: nextPage),
      loadingMore: true,
      error: null,
    ));
    await _fetchCurrent(append: true);
  }

  Future<void> _fetchCurrent({required bool append}) async {
    try {
      final page = await _repo.list(_state.filters);
      _set(_state.copyWith(
        items: append ? [..._state.items, ...page.items] : page.items,
        meta: page.meta,
        initialLoading: false,
        loadingMore: false,
        error: null,
      ));
    } catch (e) {
      _set(_state.copyWith(
        initialLoading: false,
        loadingMore: false,
        error: ErrorHandler.getUserFriendlyMessage(e),
      ));
    }
  }
}

final schoolsListControllerProvider =
    ChangeNotifierProvider.autoDispose<SchoolsListController>((ref) {
  return SchoolsListController(ref.watch(schoolRepositoryProvider));
});
