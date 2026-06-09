import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../models/auth_models.dart';

class AuthRepository {
  final ApiClient apiClient;

  /// GoogleSignIn is intentionally NOT stored as a field.
  /// It is created lazily inside [loginWithGoogle] so that:
  ///   - The app never crashes at startup due to a missing clientId.
  ///   - Platform guards run only when the user actually taps "Sign in with Google".
  AuthRepository({ApiClient? apiClient})
      : apiClient = apiClient ?? ApiClient();

  // ---------------------------------------------------------------------------
  // Google Sign-In helpers
  // ---------------------------------------------------------------------------

  /// Creates a [GoogleSignIn] instance configured for the current platform.
  ///
  /// Throws [AppException] when:
  ///   - [GOOGLE_WEB_CLIENT_ID] is not provided at compile time.
  ///   - The current platform is macOS desktop (plugin not supported).
  GoogleSignIn _createGoogleSignIn() {
    // macOS desktop: the google_sign_in plugin does not support native macOS
    // flows. Fail fast with a friendly message before Flutter crashes.
    if (!kIsWeb && Platform.isMacOS) {
      throw const AppException(
        'Google login is not supported in this macOS desktop build. '
        'Use Chrome, Android, or email login.',
      );
    }

    final clientId = AppConfig.googleWebClientId;
    if (clientId.isEmpty) {
      throw const AppException(
        'Google login is not configured. '
        'Please provide GOOGLE_WEB_CLIENT_ID via --dart-define.',
      );
    }

    // On Web the plugin requires `clientId`.
    // On Android / iOS the plugin uses the google-services.json / plist; we
    // pass `serverClientId` so the backend can verify the returned idToken.
    return GoogleSignIn(
      clientId: kIsWeb ? clientId : null,
      serverClientId: !kIsWeb ? clientId : null,
      scopes: ['email', 'profile'],
    );
  }

  // ---------------------------------------------------------------------------
  // Auth operations
  // ---------------------------------------------------------------------------

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return _saveAuthResponse(response.data);
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await apiClient.dio.post(
      '/auth/register',
      data: {
        'name': name,
        'displayName': name,
        'email': email,
        'password': password,
      },
    );
    return _saveAuthResponse(response.data);
  }

  Future<AuthResponse> loginWithGoogle() async {
    // _createGoogleSignIn() performs all platform and config checks and throws
    // AppException with a user-friendly message on any problem. This keeps
    // the error out of app-startup and surfaces it only when the user taps
    // the Google button.
    final googleSignIn = _createGoogleSignIn();

    final account = await googleSignIn.signIn();
    if (account == null) {
      throw const AppException('Google sign-in was cancelled.');
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const AppException('Google did not return an id token.');
    }

    final response = await apiClient.dio.post(
      '/auth/google',
      data: {'idToken': idToken},
    );
    return _saveAuthResponse(response.data);
  }

  Future<void> forgotPassword(String email) async {
    await apiClient.dio.post('/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await apiClient.dio.post(
      '/auth/reset-password',
      data: {'token': token, 'newPassword': newPassword},
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await apiClient.dio.post(
      '/auth/change-password',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  Future<UserModel> me() async {
    final response = await apiClient.dio.get('/auth/me');
    final data = ApiEnvelope.unwrapData(asJsonMap(response.data));
    if (data is! Map) {
      throw const ApiException('Backend did not return a user.');
    }
    return UserModel.fromJson(asJsonMap(data));
  }

  Future<AuthTokens> refreshToken() async {
    final refreshToken = await apiClient.tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const AppException('No refresh token is available.');
    }

    final response = await apiClient.dio.post(
      '/auth/refresh-token',
      data: {'refreshToken': refreshToken},
    );
    final data = ApiEnvelope.unwrapData(asJsonMap(response.data));
    if (data is! Map) {
      throw const ApiException('Backend did not return auth tokens.');
    }
    final tokens = AuthTokens.fromJson(asJsonMap(data));
    await apiClient.tokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    return tokens;
  }

  Future<void> logout() async {
    try {
      await apiClient.dio.post('/auth/logout');
    } catch (_) {
      // Local logout must still succeed if the token is already expired.
    }

    // Attempt a Google sign-out only when it is safe to do so.
    // Skip on macOS desktop and when no clientId is configured, because
    // _createGoogleSignIn() would throw and we still need to clear the session.
    final bool googleSignOutSafe =
        kIsWeb || (!kIsWeb && !Platform.isMacOS && AppConfig.googleWebClientId.isNotEmpty);

    if (googleSignOutSafe) {
      try {
        final gs = GoogleSignIn(
          clientId: kIsWeb ? AppConfig.googleWebClientId : null,
          serverClientId: !kIsWeb ? AppConfig.googleWebClientId : null,
        );
        await gs.signOut();
      } catch (_) {
        // Google sign-out failure must not block local session cleanup.
      }
    }

    await apiClient.tokenStorage.clear();
  }

  Future<void> clearSession() => apiClient.tokenStorage.clear();

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<AuthResponse> _saveAuthResponse(dynamic responseData) async {
    final data = ApiEnvelope.unwrapData(asJsonMap(responseData));
    if (data is! Map) {
      throw const ApiException('Backend auth response is invalid.');
    }
    final dataMap = asJsonMap(data);
    final tokens = AuthTokens.fromJson(dataMap);
    await apiClient.tokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    final user = await _readUserFromAuthData(dataMap, tokens.accessToken);
    final authResponse = AuthResponse(user: user, tokens: tokens);
    return authResponse;
  }

  Future<UserModel> _readUserFromAuthData(
    Map<String, dynamic> data,
    String accessToken,
  ) async {
    final user = data['user'];
    if (user is Map) return UserModel.fromJson(asJsonMap(user));

    try {
      return await me();
    } catch (_) {
      return _userFromJwt(accessToken);
    }
  }

  UserModel _userFromJwt(String token) {
    final parts = token.split('.');
    if (parts.length < 2) {
      throw const ApiException('Backend did not return a user.');
    }

    final normalized = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final payload = asJsonMap(jsonDecode(decoded));
    return UserModel.fromJson(payload);
  }
}
