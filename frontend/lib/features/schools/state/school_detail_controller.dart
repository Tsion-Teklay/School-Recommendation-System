import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_dtos.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/state/auth_controller.dart';
import '../data/school_dtos.dart';
import '../data/school_repository.dart';

class SchoolDetailState {
  final School? school;
  final bool loading;
  final String? error;
  final bool isFollowing;
  final bool followBusy;

  const SchoolDetailState({
    required this.school,
    required this.loading,
    required this.error,
    required this.isFollowing,
    required this.followBusy,
  });

  SchoolDetailState copyWith({
    School? school,
    bool? loading,
    Object? error = _sentinel,
    bool? isFollowing,
    bool? followBusy,
  }) {
    return SchoolDetailState(
      school: school ?? this.school,
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      isFollowing: isFollowing ?? this.isFollowing,
      followBusy: followBusy ?? this.followBusy,
    );
  }
}

const _sentinel = Object();

class SchoolDetailController extends ChangeNotifier {
  final SchoolRepository _repo;
  final int schoolId;
  final bool _canFollow;

  SchoolDetailController(this._repo, this.schoolId,
      {required bool canFollow})
      : _canFollow = canFollow {
    load();
  }

  SchoolDetailState _state = const SchoolDetailState(
    school: null,
    loading: true,
    error: null,
    isFollowing: false,
    followBusy: false,
  );
  SchoolDetailState get state => _state;

  bool _disposed = false;
  void _set(SchoolDetailState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    _set(_state.copyWith(loading: true, error: null));
    try {
      final school = await _repo.getById(schoolId);
      // Only check follow status for parents — the backend rejects others
      // with 403 on /api/me/follows.
      var following = false;
      if (_canFollow) {
        try {
          final ids = await _repo.myFollowedSchoolIds();
          following = ids.contains(schoolId);
        } catch (_) {
          // Soft-fail the follow lookup so the detail page still renders if
          // /api/me/follows is briefly unavailable.
        }
      }
      _set(_state.copyWith(
        school: school,
        loading: false,
        error: null,
        isFollowing: following,
      ));
    } on ApiException catch (e) {
      _set(_state.copyWith(loading: false, error: e.message));
    } catch (e) {
      _set(_state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> toggleFollow() async {
    if (!_canFollow || _state.school == null || _state.followBusy) return;
    final wasFollowing = _state.isFollowing;
    final school = _state.school!;
    // Optimistic toggle; rollback if the API call fails.
    _set(_state.copyWith(
      isFollowing: !wasFollowing,
      followBusy: true,
      school: school,
    ));
    try {
      if (wasFollowing) {
        await _repo.unfollow(schoolId);
      } else {
        await _repo.follow(schoolId);
      }
      // Refresh follower count from the server so the UI reflects the new
      // total (the backend recomputes it on every detail fetch).
      final fresh = await _repo.getById(schoolId);
      _set(_state.copyWith(
        school: fresh,
        followBusy: false,
        error: null,
      ));
    } catch (e) {
      _set(_state.copyWith(
        isFollowing: wasFollowing,
        followBusy: false,
        error: e is ApiException ? e.message : e.toString(),
      ));
    }
  }
}

final schoolDetailControllerProvider = ChangeNotifierProvider.family
    .autoDispose<SchoolDetailController, int>((ref, id) {
  final auth = ref.watch(authControllerProvider);
  return SchoolDetailController(
    ref.watch(schoolRepositoryProvider),
    id,
    canFollow: auth.user?.role == UserRole.parent,
  );
});
