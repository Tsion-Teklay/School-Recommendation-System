import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps `flutter_secure_storage` so swapping the backing store later (e.g. an
/// in-memory mock for tests, or Hive on platforms where secure_storage breaks)
/// is a one-class change. We deliberately do NOT cache the token in memory:
/// every call reads from the platform-native store. This keeps logout
/// instantaneous (no stale references) and matches how the dio interceptor
/// resolves the bearer header on every request.
class AuthStorage {
  static const _tokenKey = 'jwt_token';

  final FlutterSecureStorage _storage;

  AuthStorage([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> clear() => _storage.delete(key: _tokenKey);
}

final authStorageProvider = Provider<AuthStorage>((ref) => AuthStorage());
