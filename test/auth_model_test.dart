import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maihongo/core/network/api_client.dart';
import 'package:maihongo/features/auth/models/auth_models.dart';

void main() {
  test('AuthResponse parses backend auth response with _id', () {
    final response = AuthResponse.fromJson({
      'user': {
        '_id': 'user-1',
        'email': 'student@example.com',
        'displayName': 'Student',
        'role': 'learner',
        'provider': 'local',
        'emailVerified': false,
      },
      'accessToken': 'access-token',
      'refreshToken': 'refresh-token',
    });

    expect(response.user.id, 'user-1');
    expect(response.user.name, 'Student');
    expect(response.tokens.accessToken, 'access-token');
    expect(response.tokens.refreshToken, 'refresh-token');
  });

  test('ApiEnvelope throws readable backend error message', () {
    expect(
      () => ApiEnvelope.unwrapData({
        'success': false,
        'message': 'Email already registered.',
      }),
      throwsA(isA<ApiException>()),
    );
  });

  test('ApiClient describes validation errors with field messages', () {
    final requestOptions = RequestOptions(path: '/auth/register');
    final error = DioException(
      requestOptions: requestOptions,
      response: Response<dynamic>(
        requestOptions: requestOptions,
        statusCode: 400,
        data: {
          'success': false,
          'message': 'The request is invalid.',
          'code': 'BAD_REQUEST',
          'errors': [
            {
              'path': 'body.password',
              'message': 'Password must include an uppercase letter.',
            },
          ],
        },
      ),
      type: DioExceptionType.badResponse,
    );

    expect(
      ApiClient.describeError(error),
      'Password must include an uppercase letter.',
    );
  });

  test('AuthTokens accepts legacy token-only backend response', () {
    final tokens = AuthTokens.fromJson({'token': 'legacy-access-token'});

    expect(tokens.accessToken, 'legacy-access-token');
    expect(tokens.refreshToken, '');
  });
}
