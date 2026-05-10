import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import 'auth_dtos.dart';

/// Translates the backend's error envelope into a thrown ApiException so
/// screens can show a single line.
///
/// Backend envelope (see `backend/src/middlewares/error.middleware.js`):
///   { "error": "Invalid credentials", "code": "UNAUTHORIZED", "details"?: ... }
///
/// We accept `message` as a fallback for forward compatibility, but the
/// authoritative key today is `error`.
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? code;
  ApiException(this.message, {this.statusCode, this.code});

  @override
  String toString() => message;
}

ApiException _toApiException(Response<dynamic> r) {
  final data = r.data;
  if (data is Map) {
    final msg = (data['error'] ?? data['message'])?.toString() ?? 'Request failed';
    final code = data['code']?.toString();
    return ApiException(msg, statusCode: r.statusCode, code: code);
  }
  return ApiException('Request failed (${r.statusCode})', statusCode: r.statusCode);
}

/// Thin wrapper around the Phase 0–1 auth + user-profile endpoints. One method
/// per route; no caching, no retry — keeps it easy to reason about and matches
/// the backend's request/response surface exactly.
class AuthRepository {
  final Dio _dio;
  AuthRepository(this._dio);

  /// Register a new user. The backend requires at least one of `email` or
  /// `phone`; the caller decides which path they're on. Phone-only signups
  /// skip the verification email entirely and the account is usable
  /// immediately.
  Future<void> register({
    required String fullName,
    String? email,
    String? phone,
    required String password,
    required UserRole role,
  }) async {
    assert(
      (email != null && email.isNotEmpty) ||
          (phone != null && phone.isNotEmpty),
      'register: must provide email or phone',
    );
    final res = await _dio.post('/api/auth/register', data: {
      'fullName': fullName,
      if (email != null && email.isNotEmpty) 'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'password': password,
      'role': role.toWire(),
    });
    if (res.statusCode != 201) throw _toApiException(res);
  }

  /// Log in by email or phone. The backend accepts a single `identifier`
  /// field — anything containing `@` is matched against the email column,
  /// everything else against the phone column.
  Future<LoginResult> login(String identifier, String password) async {
    final res = await _dio.post('/api/auth/login', data: {
      'identifier': identifier,
      'password': password,
    });
    if (res.statusCode != 200) throw _toApiException(res);
    final body = res.data as Map<String, dynamic>;
    return LoginResult(
      token: body['token'] as String,
      user: AppUser.fromJson(body['user'] as Map<String, dynamic>),
    );
  }

  Future<void> verifyEmail(String token) async {
    final res =
        await _dio.post('/api/auth/verify-email', data: {'token': token});
    if (res.statusCode != 200) throw _toApiException(res);
  }

  Future<void> resendVerification(String email) async {
    final res = await _dio
        .post('/api/auth/resend-verification', data: {'email': email});
    if (res.statusCode != 200) throw _toApiException(res);
  }

  Future<void> forgotPassword(String email) async {
    final res =
        await _dio.post('/api/auth/forgot-password', data: {'email': email});
    if (res.statusCode != 200) throw _toApiException(res);
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final res = await _dio.post('/api/auth/reset-password',
        data: {'token': token, 'newPassword': newPassword});
    if (res.statusCode != 200) throw _toApiException(res);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await _dio.post('/api/auth/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    if (res.statusCode != 200) throw _toApiException(res);
  }

  Future<AppUser> getMe() async {
    final res = await _dio.get('/api/users/me');
    if (res.statusCode != 200) throw _toApiException(res);
    return AppUser.fromJson(
        (res.data as Map<String, dynamic>)['user'] as Map<String, dynamic>);
  }

  Future<AppUser> updateMe({String? fullName, String? phone}) async {
    final res = await _dio.put('/api/users/me', data: {
      if (fullName != null) 'fullName': fullName,
      if (phone != null) 'phone': phone,
    });
    if (res.statusCode != 200) throw _toApiException(res);
    return AppUser.fromJson(
        (res.data as Map<String, dynamic>)['user'] as Map<String, dynamic>);
  }

  Future<void> deactivateMe() async {
    final res = await _dio.post('/api/users/me/deactivate');
    if (res.statusCode != 200) throw _toApiException(res);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider).dio);
});
