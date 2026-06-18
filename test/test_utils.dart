import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:maihongo/core/network/api_client.dart';
import 'package:maihongo/core/storage/local_database_service.dart';
import 'package:maihongo/core/storage/token_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MemoryTokenStorage extends TokenStorage {
  String? accessToken;
  String? refreshToken;

  MemoryTokenStorage();

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<bool> hasSession() async =>
      (accessToken?.isNotEmpty ?? false) || (refreshToken?.isNotEmpty ?? false);

  @override
  Future<void> saveTokens({
    required String accessToken,
    String refreshToken = '',
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }
}

class FakeHttpClientAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  FakeHttpClientAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ApiClient fakeApiClient(
  Future<ResponseBody> Function(RequestOptions options) handler,
) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
  dio.httpClientAdapter = FakeHttpClientAdapter(handler);
  return ApiClient(dio: dio, tokenStorage: MemoryTokenStorage());
}

ResponseBody jsonResponse(Object data, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

Future<LocalDatabaseService> openTestDatabase(String name) async {
  sqfliteFfiInit();
  final directory = await Directory.systemTemp.createTemp(name);
  return LocalDatabaseService.open(
    directory: directory.path,
    databaseFactory: databaseFactoryFfi,
    name: name,
  );
}
