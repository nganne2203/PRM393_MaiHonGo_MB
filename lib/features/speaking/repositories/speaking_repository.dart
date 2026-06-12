import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../../../core/network/api_client.dart';
import '../data/speaking_local_store.dart';
import '../models/speaking_models.dart';

class SpeakingRepository {
  final ApiClient apiClient;
  final SpeakingLocalStore localStore;
  final Connectivity connectivity;

  SpeakingRepository({
    ApiClient? apiClient,
    SpeakingLocalStore? localStore,
    Connectivity? connectivity,
  })  : apiClient = apiClient ?? ApiClient(),
        localStore = localStore ?? SpeakingLocalStore(),
        connectivity = connectivity ?? Connectivity();

  Future<List<SpeakingPrompt>> getPrompts(String lessonId) async {
    final response = await apiClient.dio.get(
      '/speaking/prompts',
      queryParameters: lessonId.isEmpty ? null : {'lessonId': lessonId},
    );
    return parsePromptListEnvelope(_asMap(response.data));
  }

  Future<SpeakingPrompt> getPrompt(String id) async {
    final response = await apiClient.dio.get('/speaking/prompts/$id');
    final data = ApiEnvelope.unwrapData(_asMap(response.data));
    if (data is! Map) {
      throw const ApiException('Speaking prompt response is invalid.');
    }
    return SpeakingPrompt.fromJson(
      data.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  Future<SpeakingAttempt> submitAttempt({
    required String promptId,
    required String lessonId,
    required String audioPath,
    required String clientAttemptId,
    required String syncSource,
  }) async {
    if (!await isOnline()) {
      final pending = PendingSpeakingAttempt(
        promptId: promptId,
        lessonId: lessonId,
        audioPath: audioPath,
        clientAttemptId: clientAttemptId,
        syncSource: 'offline',
        createdAt: DateTime.now(),
      );
      await localStore.addPendingAttempt(pending);
      return SpeakingAttempt.pendingSync(pending);
    }

    return _submitMultipart(
      promptId: promptId,
      lessonId: lessonId,
      audioPath: audioPath,
      clientAttemptId: clientAttemptId,
      syncSource: syncSource,
    );
  }

  Future<List<SpeakingAttempt>> getAttempts({String? lessonId}) async {
    final path = lessonId == null || lessonId.isEmpty
        ? '/speaking/attempts'
        : '/speaking/attempts/$lessonId';
    final response = await apiClient.dio.get(path);
    final remote = parseAttemptListEnvelope(_asMap(response.data));
    final pending = await localStore.loadPendingAttempts();
    return [
      ...pending.map(SpeakingAttempt.pendingSync),
      ...remote,
    ];
  }

  Future<List<SpeakingAttempt>> syncPendingAttempts() async {
    if (!await isOnline()) return [];

    final synced = <SpeakingAttempt>[];
    final pendingAttempts = await localStore.loadPendingAttempts();
    for (final pending in pendingAttempts) {
      try {
        final attempt = await _submitMultipart(
          promptId: pending.promptId,
          lessonId: pending.lessonId,
          audioPath: pending.audioPath,
          clientAttemptId: pending.clientAttemptId,
          syncSource: 'offline',
        );
        await localStore.removePendingAttempt(pending.clientAttemptId);
        synced.add(attempt);
      } catch (_) {
        // Keep failed items queued; users can retry when auth/network is fixed.
      }
    }
    return synced;
  }

  Future<bool> isOnline() async {
    final results = await connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  Future<SpeakingAttempt> _submitMultipart({
    required String promptId,
    required String lessonId,
    required String audioPath,
    required String clientAttemptId,
    required String syncSource,
  }) async {
    final formData = FormData.fromMap({
      'promptId': promptId,
      'lessonId': lessonId,
      'clientAttemptId': clientAttemptId,
      'syncSource': syncSource,
      'audioFile': await MultipartFile.fromFile(
        audioPath,
        filename: _fileName(audioPath),
        contentType: MediaType.parse(_audioMimeType(audioPath)),
      ),
    });

    final response = await apiClient.dio.post(
      '/speaking/attempts',
      data: formData,
    );
    return parseAttemptEnvelope(_asMap(response.data));
  }

  static List<SpeakingPrompt> parsePromptListEnvelope(
    Map<String, dynamic> envelope,
  ) {
    final data = ApiEnvelope.unwrapData(envelope);
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((item) => SpeakingPrompt.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ))
        .toList();
  }

  static SpeakingAttempt parseAttemptEnvelope(Map<String, dynamic> envelope) {
    final data = ApiEnvelope.unwrapData(envelope);
    if (data is! Map) {
      throw const ApiException('Speaking attempt response is invalid.');
    }
    return SpeakingAttempt.fromJson(
      data.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  static List<SpeakingAttempt> parseAttemptListEnvelope(
    Map<String, dynamic> envelope,
  ) {
    final data = ApiEnvelope.unwrapData(envelope);
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((item) => SpeakingAttempt.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ))
        .toList();
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  throw const ApiException('Backend response is invalid.');
}

String _fileName(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.split('/').last;
}

String _audioMimeType(String path) {
  final detected = lookupMimeType(path);
  if (detected != null && detected.startsWith('audio/')) return detected;

  final lower = path.toLowerCase();
  if (lower.endsWith('.mp3')) return 'audio/mpeg';
  if (lower.endsWith('.wav')) return 'audio/wav';
  if (lower.endsWith('.aac')) return 'audio/aac';
  if (lower.endsWith('.webm')) return 'audio/webm';
  return 'audio/mp4';
}
