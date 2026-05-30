import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/error_handler.dart';
import '../../auth/data/auth_dtos.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/state/auth_controller.dart';
import '../data/announcement_dtos.dart';
import '../data/announcement_repository.dart';

/// Paginated controller for `/announcements`. Mirrors the schools list
/// controller (Phase 8) — `refresh()` resets to page 1, `loadMore()`
/// appends one more page, `applyFilters()` resets when filters change.
///
/// `followedOnly` only makes sense for parents (the backend ignores it
/// for everyone else), so the controller hides the toggle from non-parent
/// roles by clearing the value automatically.
class AnnouncementsFeedController extends ChangeNotifier {
  final AnnouncementRepository _repo;
  final Ref _ref;

  AnnouncementsFeedController(this._repo, this._ref);

  bool _initialized = false;
  bool _loading = false;
  bool _appending = false;
  String? _error;

  // Filter state.
  AnnouncementCategory? _category;
  UrgencyLevel? _urgency;
  bool _followedOnly = false;
  int? _schoolId;
  PublisherType? _publisherType;

  final List<Announcement> _items = [];
  int _page = 1;
  int _totalPages = 1;
  static const int _pageSize = 20;

  bool get initialized => _initialized;
  bool get loading => _loading;
  bool get appending => _appending;
  String? get error => _error;
  bool get hasMore => _page < _totalPages;
  List<Announcement> get items => List.unmodifiable(_items);

  AnnouncementCategory? get category => _category;
  UrgencyLevel? get urgency => _urgency;
  bool get followedOnly => _followedOnly;
  int? get schoolId => _schoolId;
  PublisherType? get publisherType => _publisherType;

  /// Convenience — the followedOnly filter is parent-only.
  bool get canFollowedOnly =>
      _ref.read(authControllerProvider).user?.role == UserRole.parent;

  Future<void> ensureLoaded() async {
    if (_initialized) return;
    await refresh();
  }

  Future<void> refresh() => _load(reset: true);

  Future<void> applyFilters({
    Object? category = _sentinel,
    Object? urgency = _sentinel,
    bool? followedOnly,
    Object? schoolId = _sentinel,
    Object? publisherType = _sentinel,
  }) async {
    if (!identical(category, _sentinel)) {
      _category = category as AnnouncementCategory?;
    }
    if (!identical(urgency, _sentinel)) {
      _urgency = urgency as UrgencyLevel?;
    }
    if (followedOnly != null) _followedOnly = followedOnly;
    if (!identical(schoolId, _sentinel)) {
      _schoolId = schoolId as int?;
    }
    if (!identical(publisherType, _sentinel)) {
      _publisherType = publisherType as PublisherType?;
    }
    if (!canFollowedOnly) _followedOnly = false;
    await _load(reset: true);
  }

  Future<void> loadMore() async {
    if (_appending || _loading || !hasMore) return;
    _appending = true;
    notifyListeners();
    try {
      final next = _page + 1;
      final result = await _repo.list(
        page: next,
        limit: _pageSize,
        category: _category,
        urgencyLevel: _urgency,
        schoolId: _schoolId,
        followedOnly: _followedOnly ? true : null,
        publisherType: _publisherType,
      );
      _items.addAll(result.items);
      _page = result.page;
      _totalPages = result.totalPages;
    } on ApiException catch (e) {
      _error = ErrorHandler.getUserFriendlyMessage(e);
    } catch (e) {
      _error = ErrorHandler.getUserFriendlyMessage(e);
    } finally {
      _appending = false;
      notifyListeners();
    }
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
      final result = await _repo.list(
        page: 1,
        limit: _pageSize,
        category: _category,
        urgencyLevel: _urgency,
        schoolId: _schoolId,
        followedOnly: _followedOnly ? true : null,
        publisherType: _publisherType,
      );
      _items
        ..clear()
        ..addAll(result.items);
      _page = result.page;
      _totalPages = result.totalPages;
      _initialized = true;
    } on ApiException catch (e) {
      _error = ErrorHandler.getUserFriendlyMessage(e);
    } catch (e) {
      _error = ErrorHandler.getUserFriendlyMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}

const Object _sentinel = Object();

final announcementsFeedControllerProvider =
    ChangeNotifierProvider<AnnouncementsFeedController>((ref) {
  return AnnouncementsFeedController(
    ref.watch(announcementRepositoryProvider),
    ref,
  );
});
