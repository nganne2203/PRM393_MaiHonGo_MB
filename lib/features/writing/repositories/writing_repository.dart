import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../models/writing_models.dart';

class WritingRepository {
  static const _pendingKey = 'writing_pending_submissions';

  final ApiClient apiClient;
  final Connectivity connectivity;

  WritingRepository({
    ApiClient? apiClient,
    Connectivity? connectivity,
  })  : apiClient = apiClient ?? ApiClient(),
        connectivity = connectivity ?? Connectivity();

  Future<List<WritingPrompt>> getPrompts({String? lessonId}) async {
    final response = await apiClient.dio.get(
      '/writing/prompts',
      queryParameters: {
        if (lessonId != null && lessonId.isNotEmpty) 'lessonId': lessonId,
      },
    );
    return parsePromptListEnvelope(asJsonMap(response.data));
  }

  Future<WritingSubmission> submit(WritingSubmissionRequest request) async {
    if (!await isOnline()) {
      await _savePending(request);
      return WritingSubmission.pending(request);
    }

    final response = await apiClient.dio.post(
      '/writing/submissions',
      data: request.toJson(),
    );
    return parseSubmissionEnvelope(asJsonMap(response.data));
  }

  Future<List<WritingSubmission>> getSubmissions({String? lessonId}) async {
    final path = lessonId == null || lessonId.isEmpty
        ? '/writing/submissions'
        : '/writing/submissions/$lessonId';
    final response = await apiClient.dio.get(path);
    return parseSubmissionListEnvelope(asJsonMap(response.data));
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
        synced.add(result);
      } catch (_) {
        await _saveAllPending(pending);
        return synced;
      }
    }

    await _saveAllPending([]);
    return synced;
  }

  Future<bool> isOnline() async {
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
