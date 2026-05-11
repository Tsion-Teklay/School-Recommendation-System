import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/state/auth_controller.dart';
import '../data/notification_dtos.dart';
import '../data/notification_repository.dart';

/// Paginated controller for the inbox. Same shape as the schools list
/// controller in Phase 8: `applyFilters` resets to page 1, `loadMore`
/// appends, `refresh` reloads the current page.
///
/// We also expose a quick `unreadCount` derived from the current page so the
/// AppBar badge can render without a second fetch — call `refreshUnreadCount`
/// to recompute against the live `unread=true` count.
class NotificationsController extends ChangeNotifier {
  final NotificationRepository _repo;
  final Ref _ref;

  NotificationsController(this._repo, this._ref);

  bool _initialized = false;
  bool _loading = false;
  bool _appending = false;
  String? _error;
  bool _unreadOnly = false;

  final List<AppNotification> _items = [];
  int _page = 1;
  int _totalPages = 1;

  /// Last known total unread count (computed by `refreshUnreadCount`). Used
  /// for the AppBar badge.
  int _unreadTotal = 0;

  bool get initialized => _initialized;
  bool get loading => _loading;
  bool get appending => _appending;
  String? get error => _error;
  bool get unreadOnly => _unreadOnly;
  List<AppNotification> get items => List.unmodifiable(_items);
  bool get hasMore => _page < _totalPages;
  int get unreadTotal => _unreadTotal;

  Future<void> setUnreadOnly(bool value) async {
    if (_unreadOnly == value) return;
    _unreadOnly = value;
    await _load(reset: true);
  }

  Future<void> refresh() => _load(reset: true);

  Future<void> loadMore() async {
    if (_appending || !hasMore) return;
    _appending = true;
    notifyListeners();
    try {
      final next = _page + 1;
      final result = await _repo.list(
        page: next,
        unreadOnly: _unreadOnly,
      );
      _items.addAll(result.items);
      _page = result.page;
      _totalPages = result.totalPages;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _appending = false;
      notifyListeners();
    }
  }

  Future<void> ensureLoaded() async {
    if (_initialized) return;
    await _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    _loading = true;
    _error = null;
    if (reset) {
      _items.clear();
      _page = 1;
    }
    notifyListeners();
    try {
      final result = await _repo.list(page: 1, unreadOnly: _unreadOnly);
      _items
        ..clear()
        ..addAll(result.items);
      _page = result.page;
      _totalPages = result.totalPages;
      _initialized = true;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
    // Keep the badge in sync.
    unawaited(refreshUnreadCount());
  }

  Future<void> markRead(int id) async {
    try {
      await _repo.markRead(id);
      final i = _items.indexWhere((n) => n.id == id);
      if (i >= 0) {
        _items[i] = _items[i].markedRead();
      }
      if (_unreadTotal > 0) _unreadTotal--;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  /// Hits `?unread=true&limit=1` to grab the `meta.total` for the bell badge.
  /// Cheap; runs on init + after every state change.
  Future<void> refreshUnreadCount() async {
    // Only hit the endpoint while a session exists; otherwise we'll just be
    // generating noisy 401s on the auth screens.
    final auth = _ref.read(authControllerProvider);
    if (!auth.isAuthenticated) {
      _unreadTotal = 0;
      notifyListeners();
      return;
    }
    try {
      final result = await _repo.list(page: 1, limit: 1, unreadOnly: true);
      _unreadTotal = result.total;
      notifyListeners();
    } on ApiException {
      // Don't surface badge errors to the UI — silent fail is fine here.
    }
  }
}

void unawaited(Future<void> _) {}

final notificationsControllerProvider =
    ChangeNotifierProvider<NotificationsController>((ref) {
  return NotificationsController(
    ref.watch(notificationRepositoryProvider),
    ref,
  );
});
