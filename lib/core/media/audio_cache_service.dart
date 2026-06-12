import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../network/api_client.dart';

class AudioCacheService {
  final Dio dio;

  AudioCacheService({ApiClient? apiClient})
      : dio = apiClient?.dio ?? ApiClient().dio;

  Future<String?> cachedPathForUrl(String url) async {
    if (url.trim().isEmpty) return null;
    final file = await _cacheFile(url);
    return file.existsSync() ? file.path : null;
  }

  Future<String> cacheRemoteAudio(String url) async {
    if (url.trim().isEmpty) {
      throw const ApiException('Audio is not available yet.');
    }

    final file = await _cacheFile(url);
    if (await file.exists()) return file.path;

    await file.parent.create(recursive: true);
    await dio.download(url, file.path);
    return file.path;
  }

  Future<File> _cacheFile(String url) async {
    final directory = await getApplicationDocumentsDirectory();
    final safeName = Uri.encodeComponent(url);
    return File('${directory.path}/audio-cache/$safeName');
  }
}
