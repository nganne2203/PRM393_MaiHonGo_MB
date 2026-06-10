import 'api_client.dart';

class AuthApi {
  final ApiClient apiClient;

  AuthApi({ApiClient? apiClient}) : apiClient = apiClient ?? ApiClient();

  Future<bool> hasSavedToken() async {
    return apiClient.tokenStorage.hasSession();
  }

  Future<void> logout() async {
    await apiClient.tokenStorage.clear();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    await _saveToken(response.data);
  }

  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final response = await apiClient.dio.post(
      '/auth/register',
      data: {
        'name': displayName,
        'displayName': displayName,
        'email': email,
        'password': password,
      },
    );
    await _saveToken(response.data);
  }

  Future<void> _saveToken(dynamic responseData) async {
    final data = ApiEnvelope.unwrapData(
      responseData is Map<String, dynamic>
          ? responseData
          : Map<String, dynamic>.from(responseData as Map),
    );
    if (data is! Map) {
      throw const ApiException('Backend auth response is invalid.');
    }
    final accessToken =
        data['accessToken']?.toString() ?? data['token']?.toString();
    final refreshToken = data['refreshToken']?.toString() ?? '';
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException('Backend did not return an auth token.');
    }
    await apiClient.tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}
