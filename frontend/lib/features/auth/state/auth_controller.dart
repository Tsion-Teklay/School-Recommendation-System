import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/auth_storage.dart';
import '../data/auth_dtos.dart';
import '../data/auth_repository.dart';

/// Three-state auth model: initializing (we haven't checked storage yet),
/// authenticated (token + user loaded), unauthenticated (no token or token was
/// rejected).
///
/// Why a `ChangeNotifier` and not a `StateNotifier`/`AsyncValue`? go_router's
/// `refreshListenable` wants a `Listenable`, and the simplest interop is a
/// `ChangeNotifier` that doubles as the source of auth state. Riverpod still
/// owns instantiation via the provider below.
class AuthController extends ChangeNotifier {
  final AuthRepository _repo;
  final AuthStorage _storage;

  AuthController(this._repo, this._storage, ApiClient apiClient) {
    // Wire the 401 signal: the interceptor has already cleared the token from
    // storage, we just need to drop the in-memory user and notify listeners
    // so the router redirects to /login.
    apiClient.onUnauthorized = _handleUnauthorized;
    _bootstrap();
  }

  void _handleUnauthorized() {
    if (_user == null) return;
    _user = null;
    notifyListeners();
  }

  bool _initializing = true;
  AppUser? _user;

  bool get initializing => _initializing;
  AppUser? get user => _user;
  bool get isAuthenticated => !_initializing && _user != null;

  Future<void> _bootstrap() async {
    final token = await _storage.readToken();
    if (token == null) {
      _initializing = false;
      notifyListeners();
      return;
    }
    try {
      _user = await _repo.getMe();
    } on ApiException catch (e) {
      // Only clear on 401 — that's the server explicitly rejecting the token.
      // 5xx is a transient backend problem; clearing the token would log the
      // user out for the duration of the outage. The 401 interceptor would
      // also fire onUnauthorized, but we set _user ourselves anyway so
      // isAuthenticated stays consistent.
      if (e.statusCode == 401) {
        await _storage.clear();
      }
      _user = null;
    } catch (_) {
      // Network-level failure (DNS, timeout, airplane mode). Don't destroy a
      // potentially valid session — keep the token on disk and just treat the
      // user as unauthenticated for this boot. They'll have a session waiting
      // when connectivity returns.
      _user = null;
    }
    _initializing = false;
    notifyListeners();
  }

  Future<void> login(String identifier, String password) async {
    final result = await _repo.login(identifier, password);
    await _storage.writeToken(result.token);
    _user = result.user;
    notifyListeners();
  }

  Future<void> register({  
  required String fullName,  
  String? email,  
  String? phone,  
  required String password,  
  required UserRole role,  
  String? subCity,  
  String? officerRole,  
}) async {  
  await _repo.register(  
    fullName: fullName,  
    email: email,  
    phone: phone,  
    password: password,  
    role: role,  
    subCity: subCity,  
    officerRole: officerRole,  
  );  
}

  Future<void> logout() async {
    await _storage.clear();
    _user = null;
    notifyListeners();
  }

  Future<void> updateProfile({String? fullName, String? phone}) async {
    final updated = await _repo.updateMe(fullName: fullName, phone: phone);
    _user = updated;
    notifyListeners();
  }

  Future<void> deactivate() async {
    await _repo.deactivateMe();
    await _storage.clear();
    _user = null;
    notifyListeners();
  }

  Future<void> reactivate(String identifier, String password) async {  
  final result = await _repo.reactivate(identifier, password);  
  await _storage.writeToken(result.token);  
  _user = result.user;  
  notifyListeners();  
}

Future<void> deletePermanently(String password) async {  
  await _repo.deleteMePermanently(password);  
  await _storage.clear();  
  _user = null;  
  notifyListeners();  
}

}

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(authStorageProvider),
    ref.watch(apiClientProvider),
  );
});
