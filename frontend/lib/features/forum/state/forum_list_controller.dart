import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../data/forum_dtos.dart';
import '../data/forum_repository.dart';

class ForumListController extends ChangeNotifier {
  final ForumRepository _repo;
  ForumListController(this._repo);

  bool _initialized = false;
  bool _loading = false;
  bool _appending = false;
  String? _error;
  final List<ForumPost> _items = [];
  int _page = 1;
  int _totalPages = 1;

  bool get initialized => _initialized;
  bool get loading => _loading;
  bool get appending => _appending;
  String? get error => _error;
  List<ForumPost> get items => List.unmodifiable(_items);
  bool get hasMore => _page < _totalPages;

  Future<void> ensureLoaded() async {
    if (_initialized || _loading) return;
    await refresh();
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final r = await _repo.list(page: 1);
      _items
        ..clear()
        ..addAll(r.items);
      _page = r.page;
      _totalPages = r.totalPages;
      _initialized = true;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_appending || !hasMore) return;
    _appending = true;
    notifyListeners();
    try {
      final r = await _repo.list(page: _page + 1);
      _items.addAll(r.items);
      _page = r.page;
      _totalPages = r.totalPages;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _appending = false;
      notifyListeners();
    }
  }

  Future<bool> create(String content) async {
    try {
      final p = await _repo.create(content);
      _items.insert(0, p);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }
}

final forumListControllerProvider =
    ChangeNotifierProvider<ForumListController>((ref) {
  return ForumListController(ref.watch(forumRepositoryProvider));
});
