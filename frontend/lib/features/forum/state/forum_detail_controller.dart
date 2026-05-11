import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../data/forum_dtos.dart';
import '../data/forum_repository.dart';

class ForumDetailController extends ChangeNotifier {
  final ForumRepository _repo;
  final int postId;
  ForumDetailController(this._repo, this.postId);

  bool _loading = false;
  bool _saving = false;
  String? _error;
  ForumPost? _post;

  bool get loading => _loading;
  bool get saving => _saving;
  String? get error => _error;
  ForumPost? get post => _post;

  Future<void> ensureLoaded() async {
    if (_post != null || _loading) return;
    await refresh();
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _post = await _repo.getById(postId);
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> reply(String content) async {
    _saving = true;
    notifyListeners();
    try {
      await _repo.reply(postId, content);
      await refresh();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _saving = false;
      notifyListeners();
      return false;
    } finally {
      _saving = false;
    }
  }

  Future<bool> updateBody(int targetId, String content) async {
    _saving = true;
    notifyListeners();
    try {
      await _repo.update(targetId, content);
      await refresh();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _saving = false;
      notifyListeners();
      return false;
    } finally {
      _saving = false;
    }
  }

  Future<bool> remove(int targetId) async {
    _saving = true;
    notifyListeners();
    try {
      await _repo.delete(targetId);
      if (targetId == postId) {
        _post = null;
      } else {
        await refresh();
      }
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _saving = false;
      notifyListeners();
      return false;
    } finally {
      _saving = false;
    }
  }
}

final forumDetailControllerProvider = ChangeNotifierProvider.family
    .autoDispose<ForumDetailController, int>((ref, id) {
  return ForumDetailController(ref.watch(forumRepositoryProvider), id);
});
