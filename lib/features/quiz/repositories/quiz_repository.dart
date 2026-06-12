import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../models/quiz_models.dart';

class QuizRepository {
  static const _pendingKey = 'quiz_pending_results';

  final ApiClient apiClient;
  final Connectivity connectivity;

  QuizRepository({
    ApiClient? apiClient,
    Connectivity? connectivity,
  })  : apiClient = apiClient ?? ApiClient(),
        connectivity = connectivity ?? Connectivity();

  Future<QuizResult> submitQuizResult(QuizSubmission submission) async {
    if (!await isOnline()) {
      await _savePending(submission);
      return QuizResult.pending(submission);
    }

    final response =
        await apiClient.dio.post('/quiz/results', data: submission.toJson());
    return parseQuizResultEnvelope(asJsonMap(response.data));
  }

  Future<List<QuizResult>> getQuizResults({String? lessonId}) async {
    final response = await apiClient.dio.get('/quiz/results');
    final remote = parseQuizResultListEnvelope(asJsonMap(response.data));
    if (lessonId == null || lessonId.isEmpty) return remote;
    return remote.where((item) => item.lessonId == lessonId).toList();
  }

  Future<List<QuizResult>> syncPendingResults() async {
    if (!await isOnline()) return [];
    final pending = await _loadPending();
    final synced = <QuizResult>[];
    for (final submission in pending) {
      try {
        final result = await submitQuizResult(
          QuizSubmission(
            lessonId: submission.lessonId,
            score: submission.score,
            total: submission.total,
            durationSec: submission.durationSec,
            answers: submission.answers,
            syncSource: 'offline',
            clientAttemptId: submission.clientAttemptId,
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

  static QuizResult parseQuizResultEnvelope(Map<String, dynamic> envelope) {
    final data = ApiEnvelope.unwrapData(envelope);
    if (data is! Map) throw const ApiException('Quiz result is invalid.');
    return QuizResult.fromJson(asJsonMap(data));
  }

  static List<QuizResult> parseQuizResultListEnvelope(
    Map<String, dynamic> envelope,
  ) {
    final data = ApiEnvelope.unwrapData(envelope);
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((item) => QuizResult.fromJson(asJsonMap(item)))
        .toList();
  }

  Future<void> _savePending(QuizSubmission submission) async {
    final pending = await _loadPending();
    final filtered = pending
        .where((item) => item.clientAttemptId != submission.clientAttemptId)
        .toList();
    filtered.add(submission);
    await _saveAllPending(filtered);
  }

  Future<List<QuizSubmission>> _loadPending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded.whereType<Map>().map((item) {
      final json = asJsonMap(item);
      final answers = json['answers'];
      return QuizSubmission(
        lessonId: json['lessonId']?.toString() ?? '',
        score: int.tryParse(json['score']?.toString() ?? '') ?? 0,
        total: int.tryParse(json['total']?.toString() ?? '') ?? 0,
        durationSec: int.tryParse(json['durationSec']?.toString() ?? '') ?? 0,
        answers: answers is List
            ? answers
                .whereType<Map>()
                .map((answer) => QuizAnswer.fromJson(asJsonMap(answer)))
                .toList()
            : const [],
        syncSource: json['syncSource']?.toString() ?? 'offline',
        clientAttemptId: json['clientAttemptId']?.toString() ?? '',
      );
    }).toList();
  }

  Future<void> _saveAllPending(List<QuizSubmission> submissions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pendingKey,
      jsonEncode(submissions.map((item) => item.toJson()).toList()),
    );
  }
}
