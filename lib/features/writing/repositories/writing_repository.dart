import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/local_database_service.dart';
import '../models/writing_models.dart';

class WritingRepository {
  static const _pendingKey = 'writing_pending_submissions';

  final ApiClient apiClient;
  final Connectivity connectivity;
  final Future<LocalDatabaseService>? _localDatabase;
  final Future<bool> Function()? _onlineCheck;

  WritingRepository({
    ApiClient? apiClient,
    Connectivity? connectivity,
    Future<LocalDatabaseService>? localDatabase,
    Future<bool> Function()? onlineCheck,
  })  : apiClient = apiClient ?? ApiClient(),
        connectivity = connectivity ?? Connectivity(),
        _localDatabase = localDatabase ?? LocalDatabaseService.open(),
        _onlineCheck = onlineCheck;

  Future<List<WritingPrompt>> getPrompts({String? lessonId}) async {
    try {
      final response = await apiClient.dio.get(
        '/writing/prompts',
        queryParameters: {
          if (lessonId != null && lessonId.isNotEmpty) 'lessonId': lessonId,
        },
      );
      final prompts = parsePromptListEnvelope(asJsonMap(response.data));
      if (lessonId != null && lessonId.isNotEmpty) {
        await _saveCachedPrompts(lessonId, prompts);
      }
      return prompts;
    } catch (_) {
      final cached = await _readCachedPrompts(lessonId ?? '');
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  Future<WritingSubmission> submit(WritingSubmissionRequest request) async {
    if (!await isOnline()) {
      await _savePending(request);
      return WritingSubmission.pending(request);
    }

    try {
      final response = await apiClient.dio.post(
        '/writing/submissions',
        data: request.toJson(),
      );
      return parseSubmissionEnvelope(asJsonMap(response.data));
    } catch (error) {
      if (!_isRetryable(error)) rethrow;
      await _savePending(request);
      return WritingSubmission.pending(request);
    }
  }

  Future<List<WritingSubmission>> getSubmissions({String? lessonId}) async {
    final path = lessonId == null || lessonId.isEmpty
        ? '/writing/submissions'
        : '/writing/submissions/$lessonId';
    final pending = await _loadPending();
    final filteredPending = lessonId == null || lessonId.isEmpty
        ? pending
        : pending.where((item) => item.lessonId == lessonId);
    try {
      final response = await apiClient.dio.get(path);
      return [
        ...filteredPending.map(WritingSubmission.pending),
        ...parseSubmissionListEnvelope(asJsonMap(response.data)),
      ];
    } catch (_) {
      if (filteredPending.isNotEmpty) {
        return filteredPending.map(WritingSubmission.pending).toList();
      }
      rethrow;
    }
  }

  Future<void> _saveCachedPrompts(
    String lessonId,
    List<WritingPrompt> prompts,
  ) async {
    try {
      final database = await _localDatabase;
      await database?.savePracticeContent(
        kind: 'writing',
        lessonId: lessonId,
        items: prompts.map(_promptToJson).toList(),
      );
    } catch (_) {}
  }

  Future<List<WritingPrompt>> _readCachedPrompts(String lessonId) async {
    if (lessonId.isEmpty) return const [];
    try {
      final database = await _localDatabase;
      final items = await database?.getPracticeContent(
            kind: 'writing',
            lessonId: lessonId,
          ) ??
          const [];
      return items.map(WritingPrompt.fromJson).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<WritingSubmission>> syncPendingSubmissions() async {
    if (!await isOnline()) return [];
    final pending = await _loadPending();
    final synced = <WritingSubmission>[];

    for (final request in pending) {
      try {
        final result = await submit(
          WritingSubmissionRequest(
            promptId: request.promptId,
            lessonId: request.lessonId,
            answerText: request.answerText,
            submittedAt: request.submittedAt,
            syncSource: 'offline',
            clientSubmissionId: request.clientSubmissionId,
          ),
        );
        if (result.pendingSync) {
          await _saveAllPending(pending);
          return synced;
        }
        synced.add(result);
      } catch (_) {
        await _saveAllPending(pending);
        return synced;
      }
    }

    await _saveAllPending([]);
    return synced;
  }

  Future<void> saveDraft({
    required String promptId,
    required String lessonId,
    required String answerText,
  }) async {
    final database = await _localDatabase;
    await database?.saveWritingDraft(
      promptId: promptId,
      lessonId: lessonId,
      answerText: answerText,
    );
  }

  Future<String?> loadDraft(String promptId) async {
    final database = await _localDatabase;
    return database?.getWritingDraft(promptId);
  }

  Future<void> clearDraft(String promptId) async {
    final database = await _localDatabase;
    await database?.clearWritingDraft(promptId);
  }

  Future<bool> isOnline() async {
    if (_onlineCheck != null) return _onlineCheck();
    final result = await connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  static List<WritingPrompt> parsePromptListEnvelope(
    Map<String, dynamic> envelope,
  ) {
    final data = ApiEnvelope.unwrapData(envelope);
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((item) => WritingPrompt.fromJson(asJsonMap(item)))
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  static WritingSubmission parseSubmissionEnvelope(
    Map<String, dynamic> envelope,
  ) {
    final data = ApiEnvelope.unwrapData(envelope);
    if (data is! Map) {
      throw const ApiException('Writing submission is invalid.');
    }
    return WritingSubmission.fromJson(asJsonMap(data));
  }

  static List<WritingSubmission> parseSubmissionListEnvelope(
    Map<String, dynamic> envelope,
  ) {
    final data = ApiEnvelope.unwrapData(envelope);
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((item) => WritingSubmission.fromJson(asJsonMap(item)))
        .toList();
  }

  Future<void> _savePending(WritingSubmissionRequest request) async {
    final pending = await _loadPending();
    final filtered = pending
        .where((item) => item.clientSubmissionId != request.clientSubmissionId)
        .toList();
    filtered.add(request);
    await _saveAllPending(filtered);
  }

  Future<List<WritingSubmissionRequest>> _loadPending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((item) => WritingSubmissionRequest.fromJson(asJsonMap(item)))
        .where((item) => item.promptId.isNotEmpty && item.lessonId.isNotEmpty)
        .toList();
  }

  Future<void> _saveAllPending(
    List<WritingSubmissionRequest> submissions,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pendingKey,
      jsonEncode(submissions.map((item) => item.toJson()).toList()),
    );
  }
}

Map<String, dynamic> _promptToJson(WritingPrompt prompt) => {
      '_id': prompt.id,
      'lessonId': prompt.lessonId,
      'lessonTitle': prompt.lessonTitle,
      'promptText': prompt.promptText,
      'promptType': prompt.promptType,
      'expectedAnswer': prompt.expectedAnswer,
      'sampleAnswer': prompt.sampleAnswer,
      'rubric': prompt.rubric,
      'difficulty': prompt.difficulty,
    };

bool _isRetryable(Object error) {
  if (error is! DioException) return false;
  return error.response == null ||
      error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout;
}
