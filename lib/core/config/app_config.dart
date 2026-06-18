import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const _configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _configuredGoogleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  static String get apiBaseUrl {
    if (_configuredApiBaseUrl.isNotEmpty) return _configuredApiBaseUrl;
    final dotenvApiBaseUrl = _dotenvValue('API_BASE_URL');
    if (dotenvApiBaseUrl.isNotEmpty) return dotenvApiBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  static String get googleWebClientId {
    if (_configuredGoogleWebClientId.isNotEmpty) {
      return _configuredGoogleWebClientId;
    }
    return _dotenvValue('GOOGLE_WEB_CLIENT_ID');
  }

  static String _dotenvValue(String key) {
    if (!dotenv.isInitialized) return '';
    return dotenv.env[key]?.trim() ?? '';
  }
}
