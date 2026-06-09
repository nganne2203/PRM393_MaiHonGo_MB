import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../errors/app_exception.dart';
import '../storage/token_storage.dart';

class ApiException extends AppException {
  const ApiException(super.message, {super.statusCode});
}

Map<String, dynamic> asJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  throw const ApiException('Backend response is invalid.');
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
  static String get defaultBaseUrl => AppConfig.apiBaseUrl;
  static const tokenKey = TokenStorage.legacyTokenKey;

  final Dio dio;
  final TokenStorage tokenStorage;

  ApiClient({
    Dio? dio,
    TokenStorage? tokenStorage,
  })  : dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: defaultBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 60),
              ),
            ),
        tokenStorage = tokenStorage ?? const TokenStorage() {
    this.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final token = await this.tokenStorage.readAccessToken();
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              handler.next(options);
            },
            onError: (error, handler) async {
              if (await _shouldRefresh(error)) {
                final refreshed = await _refreshTokens();
                if (refreshed) {
                  final response = await _retry(error.requestOptions);
                  handler.resolve(response);
                  return;
                }
                await this.tokenStorage.clear();
              }

              final apiError = toApiException(error);
              handler.reject(
                DioException(
                  requestOptions: error.requestOptions,
                  response: error.response,
                  type: error.type,
                  error: apiError,
                  message: apiError.message,
                ),
              );
            },
          ),
        );
  }

  static ApiException toApiException(
    Object error, {
    String fallbackMessage = 'Request failed.',
  }) {
    if (error is ApiException) return error;
    if (error is AppException) {
      return ApiException(error.message, statusCode: error.statusCode);
    }
    if (error is DioException) {
      final nested = error.error;
      if (nested is ApiException) return nested;
      if (nested is AppException) {
        return ApiException(nested.message, statusCode: nested.statusCode);
      }

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

  Future<bool> _shouldRefresh(DioException error) async {
    if (error.response?.statusCode != 401) return false;
    if (error.requestOptions.extra['authRetry'] == true) return false;
    if (error.requestOptions.path.contains('/auth/refresh-token')) {
      return false;
    }
    final refreshToken = await tokenStorage.readRefreshToken();
    return refreshToken != null && refreshToken.isNotEmpty;
  }

  Future<bool> _refreshTokens() async {
    final refreshToken = await tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: defaultBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      final response = await refreshDio.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );
      final data = ApiEnvelope.unwrapData(asJsonMap(response.data));
      if (data is! Map) return false;
      final accessToken =
          data['accessToken']?.toString() ?? data['token']?.toString();
      final newRefreshToken = data['refreshToken']?.toString();
      if (accessToken == null ||
          accessToken.isEmpty ||
          newRefreshToken == null ||
          newRefreshToken.isEmpty) {
        return false;
      }
      await tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final accessToken = await tokenStorage.readAccessToken();
    final headers = Map<String, dynamic>.from(requestOptions.headers);
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final options = Options(
      method: requestOptions.method,
      headers: headers,
      responseType: requestOptions.responseType,
      contentType: requestOptions.contentType,
      followRedirects: requestOptions.followRedirects,
      receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
      extra: {
        ...requestOptions.extra,
        'authRetry': true,
      },
    );

    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
      cancelToken: requestOptions.cancelToken,
      onReceiveProgress: requestOptions.onReceiveProgress,
      onSendProgress: requestOptions.onSendProgress,
    );
  }
}
