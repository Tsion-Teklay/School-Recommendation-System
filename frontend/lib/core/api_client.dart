import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_storage.dart';
import 'config.dart';

/// Single Dio instance for the whole app. The interceptor here is the only
/// place that touches the JWT for outbound requests, so we never have to
/// remember to attach the bearer header at call sites.
///
/// On a 401 response we wipe the stored token AND fire `onUnauthorized` so the
/// AuthController can null out its in-memory user and `notifyListeners()`,
/// which in turn lets the router's `refreshListenable` redirect to /login on
/// the next navigation. Without that signal the UI would still think the user
/// is logged in (because `_user` stays populated) even though every subsequent
/// request would fail with another 401.
///
/// We deliberately do NOT pop a snackbar here — UI feedback belongs to the
/// screen that initiated the request.
class ApiClient {
  final Dio dio;
  final AuthStorage _storage;

  /// Set by AuthController on construction. Invoked when a 401 is observed so
  /// the controller can drop its in-memory user and notify listeners.
  void Function()? onUnauthorized;

  ApiClient(this._storage)
      : dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
            headers: {'Content-Type': 'application/json'},
            // Don't throw on non-2xx — we want to read the JSON body to surface
            // the backend's `message` field. Each repository decides what to do
            // with the status code.
            validateStatus: (_) => true,
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onResponse: (response, handler) async {
          if (response.statusCode == 401 &&
              !_isAuthEndpoint(response.requestOptions.path)) {
            // Treat 401 as session-expired ONLY for non-auth endpoints. Auth
            // endpoints use 401 for business-logic checks (e.g.
            // change-password's "current password is incorrect", login's
            // "invalid credentials") and a logged-in user mistyping their
            // current password should NOT get bounced back to /login.
            await _storage.clear();
            onUnauthorized?.call();
          }
          handler.next(response);
        },
      ),
    );
  }

  /// HTTP POST method
  Future<Response<dynamic>> post(String path,
      {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) {
    return dio.post(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  /// HTTP GET method
  Future<Response<dynamic>> get(String path,
      {Map<String, dynamic>? queryParameters, Options? options}) {
    return dio.get(path, queryParameters: queryParameters, options: options);
  }
}

/// Auth endpoints whose 401s mean "wrong credentials / wrong current password"
/// rather than "your session expired". The interceptor skips its clear-token
/// logic for these paths.
bool _isAuthEndpoint(String path) {
  return path.startsWith('/api/auth/');
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(authStorageProvider));
});
