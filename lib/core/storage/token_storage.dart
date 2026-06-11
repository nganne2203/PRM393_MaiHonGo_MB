import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const accessTokenKey = 'auth_access_token';
  static const refreshTokenKey = 'auth_refresh_token';
  static const legacyTokenKey = 'auth_token';

  final FlutterSecureStorage secureStorage;

  const TokenStorage({
    this.secureStorage = const FlutterSecureStorage(),
  });

  bool get _useSharedPreferences =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  Future<String?> readAccessToken() async {
    final accessToken = await _read(accessTokenKey);
    return accessToken ?? await _read(legacyTokenKey);
  }

  Future<String?> readRefreshToken() => _read(refreshTokenKey);

  Future<String?> getAccessToken() => readAccessToken();

  Future<String?> getRefreshToken() => readRefreshToken();

  Future<bool> hasSession() async {
    final accessToken = await readAccessToken();
    final refreshToken = await readRefreshToken();
    return (accessToken != null && accessToken.isNotEmpty) ||
        (refreshToken != null && refreshToken.isNotEmpty);
  }

  Future<void> saveTokens({
    required String accessToken,
    String refreshToken = '',
  }) async {
    await _write(accessTokenKey, accessToken);
    await _write(legacyTokenKey, accessToken);
    if (refreshToken.isNotEmpty) {
      await _write(refreshTokenKey, refreshToken);
    } else {
      await _delete(refreshTokenKey);
    }
  }

  Future<void> clear() async {
    await _delete(accessTokenKey);
    await _delete(refreshTokenKey);
    await _delete(legacyTokenKey);
  }

  Future<void> clearTokens() => clear();

  Future<String?> _read(String key) async {
    if (_useSharedPreferences) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
    return secureStorage.read(key: key);
  }

  Future<void> _write(String key, String value) async {
    if (_useSharedPreferences) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      return;
    }
    await secureStorage.write(key: key, value: value);
  }

  Future<void> _delete(String key) async {
    if (_useSharedPreferences) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      return;
    }
    await secureStorage.delete(key: key);
  }
}
