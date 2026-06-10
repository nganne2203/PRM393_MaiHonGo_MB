import 'package:dio/dio.dart';

import 'api_client.dart';

class AuthApi {
  final ApiClient apiClient;

  AuthApi({ApiClient? apiClient}) : apiClient = apiClient ?? ApiClient();

  Future<bool> hasSavedToken() async {
    final token = await apiClient.secureStorage.read(key: ApiClient.tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await apiClient.secureStorage.delete(key: ApiClient.tokenKey);
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      await _saveToken(response.data);
    } on DioException catch (error) {
      final apiError = ApiClient.toApiException(error);
      if (apiError.statusCode == 401) {
        throw const ApiException(
          'Email or password is incorrect.',
          statusCode: 401,
        );
      }
      throw apiError;
    }
  }

  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/auth/register',
        data: {
          'displayName': displayName,
          'email': email,
          'password': password,
        },
      );
      await _saveToken(response.data);
    } on DioException catch (error) {
      final apiError = ApiClient.toApiException(error);
      if (apiError.statusCode == 409) {
        throw const ApiException(
          'This email is already registered. Sign in or use a different email.',
          statusCode: 409,
        );
      }
      throw apiError;
    }
  }

  Future<void> _saveToken(dynamic responseData) async {
    final data = ApiEnvelope.unwrapData(
      responseData is Map<String, dynamic>
          ? responseData
          : Map<String, dynamic>.from(responseData as Map),
    );
    final token = data is Map ? data['token']?.toString() : null;
    if (token == null || token.isEmpty) {
      throw const ApiException('Backend did not return an auth token.');
    }
    await apiClient.secureStorage.write(key: ApiClient.tokenKey, value: token);
  }
}
