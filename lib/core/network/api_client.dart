import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

String? _extractErrorMessage(dynamic data) {
  if (data is! Map) return null;

  final message = data['message']?.toString().trim();
  if (message != null && message.isNotEmpty) return message;

  final errors = data['errors'];
  if (errors is List && errors.isNotEmpty) {
    final first = errors.first;
    if (first is Map) {
      final nestedMessage = first['message']?.toString().trim();
      if (nestedMessage != null && nestedMessage.isNotEmpty) {
        return nestedMessage;
      }
    }
    final fallback = first.toString().trim();
    if (fallback.isNotEmpty) return fallback;
  }

  return null;
}

class ApiEnvelope {
  static dynamic unwrapData(Map<String, dynamic> envelope) {
    if (envelope['success'] != true) {
      throw ApiException(envelope['message']?.toString() ?? 'Request failed.');
    }
    return envelope['data'];
  }
}

class ApiClient {
  static const defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
  static const tokenKey = 'auth_token';

  final Dio dio;
  final FlutterSecureStorage secureStorage;

  static ApiException toApiException(
    Object error, {
    String fallbackMessage = 'Request failed.',
  }) {
    if (error is ApiException) return error;
    if (error is DioException) {
      final nested = error.error;
      if (nested is ApiException) return nested;

      return ApiException(
        _extractErrorMessage(error.response?.data) ??
            error.message ??
            fallbackMessage,
        statusCode: error.response?.statusCode,
      );
    }
    return ApiException(error.toString());
  }

  static String describeError(Object error) => toApiException(error).message;

  ApiClient({
    Dio? dio,
    FlutterSecureStorage? secureStorage,
  })  : dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: defaultBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 60),
              ),
            ),
        secureStorage = secureStorage ?? const FlutterSecureStorage() {
    this.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final token = await this.secureStorage.read(key: tokenKey);
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              handler.next(options);
            },
            onError: (error, handler) {
              final data = error.response?.data;
              final message = _extractErrorMessage(data);
              if (message != null) {
                handler.reject(
                  DioException(
                    requestOptions: error.requestOptions,
                    response: error.response,
                    type: error.type,
                    error: ApiException(
                      message,
                      statusCode: error.response?.statusCode,
                    ),
                    message: message,
                  ),
                );
                return;
              }
              handler.next(error);
            },
          ),
        );
  }
}
