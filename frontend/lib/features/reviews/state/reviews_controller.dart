import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../data/review_dtos.dart';
import '../data/review_repository.dart';

/// One controller per school detail screen instance. Family-keyed so
/// switching between schools doesn't share state.
class ReviewsController extends ChangeNotifier {
  final ReviewRepository _repo;
  final int schoolId;

  ReviewsController(this._repo, this.schoolId);

  static const int _pageSize = 10;

  bool _initialized = false;
  bool _loading = false;
  bool _saving = false;
  bool _appending = false;
  bool _hasMore = true;
  String? _error;
  final List<Review> _items = [];

  bool get initialized => _initialized;
  bool get loading => _loading;
  bool get saving => _saving;
  bool get appending => _appending;
  bool get hasMore => _hasMore;
  String? get error => _error;
  List<Review> get items => List.unmodifiable(_items);

  Future<void> ensureLoaded() async {
    if (_initialized || _loading) return;
    await refresh();
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final items = await _repo.listForSchool(schoolId, limit: _pageSize);
      _items
        ..clear()
        ..addAll(items);
      _hasMore = items.length == _pageSize;
      _initialized = true;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loading || _appending || !_hasMore) return;
    _appending = true;
    notifyListeners();
    try {
      final items = await _repo.listForSchool(
        schoolId,
        offset: _items.length,
        limit: _pageSize,
      );
      _items.addAll(items);
      _hasMore = items.length == _pageSize;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _appending = false;
      notifyListeners();
    }
  }

  Future<bool> create(ReviewInput input) async {
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      final created = await _repo.create(schoolId, input);
      _items.insert(0, created);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<bool> update(int reviewId, ReviewInput input) async {
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _repo.update(reviewId, input);
      final i = _items.indexWhere((r) => r.id == reviewId);
      if (i >= 0) _items[i] = updated;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<bool> remove(int reviewId) async {
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.delete(reviewId);
      _items.removeWhere((r) => r.id == reviewId);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}

final reviewsControllerProvider = ChangeNotifierProvider.family
    .autoDispose<ReviewsController, int>((ref, schoolId) {
  return ReviewsController(ref.watch(reviewRepositoryProvider), schoolId);
});
