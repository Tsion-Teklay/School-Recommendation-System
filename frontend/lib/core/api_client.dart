import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_storage.dart';
import 'config.dart';

/// Single Dio instance for the whole app. The interceptor here is the only
/// place that touches the JWT for outbound requests, so we never have to
/// remember to attach the bearer header at call sites.
///
/// Inbound 401s wipe the stored token; the router's auth-state listener then
/// kicks the user to /login on the next navigation. We deliberately do NOT
/// pop a snackbar here — UI feedback belongs to the screen that initiated the
/// request.
class ApiClient {
  final Dio dio;
  final AuthStorage _storage;

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
          if (response.statusCode == 401) {
            await _storage.clear();
          }
          handler.next(response);
        },
      ),
    );
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(authStorageProvider));
});
