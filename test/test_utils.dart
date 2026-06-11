import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:maihongo/core/network/api_client.dart';
import 'package:maihongo/core/storage/local_database_service.dart';
import 'package:maihongo/core/storage/local_models.dart';
import 'package:maihongo/core/storage/token_storage.dart';
import 'package:isar/isar.dart';

bool _isarInitialized = false;

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
  if (!_isarInitialized) {
    await Isar.initializeIsarCore(
      libraries: {Abi.current(): _isarCoreLibraryPath()},
    );
    _isarInitialized = true;
  }
  final directory = await Directory.systemTemp.createTemp(name);
  final isar = await Isar.open(
    [
      LocalLessonSchema,
      LocalVocabularySchema,
      LocalContentPackageSchema,
    ],
    directory: directory.path,
    name: name,
  );
  return LocalDatabaseService.fromIsar(isar);
}

String _isarCoreLibraryPath() {
  final pubCache = Platform.environment['PUB_CACHE'] ??
      '${Platform.environment['HOME']}/.pub-cache';
  final packageDir =
      '$pubCache/hosted/pub.dev/isar_flutter_libs-${Isar.version}';
  if (Platform.isMacOS) return '$packageDir/macos/libisar.dylib';
  if (Platform.isLinux) return '$packageDir/linux/libisar.so';
  if (Platform.isWindows) return '$packageDir/windows/isar.dll';
  return '';
}
