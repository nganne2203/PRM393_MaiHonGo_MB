import '../../../core/network/api_client.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final String provider;
  final String? avatar;
  final bool emailVerified;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.provider,
    this.avatar,
    required this.emailVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'] ?? json['userId'] ?? json['sub'] ?? '')
          .toString(),
      email: json['email']?.toString() ?? '',
      name: (json['name'] ?? json['displayName'] ?? json['email'] ?? 'Learner')
          .toString(),
      role: json['role']?.toString() ?? 'learner',
      provider: json['provider']?.toString() ?? 'local',
      avatar: json['avatar']?.toString(),
      emailVerified: json['emailVerified'] == true,
    );
  }
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    final tokens = json['tokens'];
    final tokenSource = tokens is Map ? asJsonMap(tokens) : json;
    final accessToken = tokenSource['accessToken']?.toString() ??
        tokenSource['token']?.toString();
    final refreshToken = tokenSource['refreshToken']?.toString() ?? '';

    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException('Backend did not return an auth token.');
    }

    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}

class AuthResponse {
  final UserModel user;
  final AuthTokens tokens;

  const AuthResponse({
    required this.user,
    required this.tokens,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    if (user is! Map) {
      throw const ApiException('Backend did not return a user.');
    }
    return AuthResponse(
      user: UserModel.fromJson(asJsonMap(user)),
      tokens: AuthTokens.fromJson(json),
    );
  }
}

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  const ApiResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic value) parseData,
  ) {
    return ApiResponse<T>(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] == null ? null : parseData(json['data']),
    );
  }
}
