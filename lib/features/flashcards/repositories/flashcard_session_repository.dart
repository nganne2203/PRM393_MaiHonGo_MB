import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/local_database_provider.dart';
import '../../../core/storage/local_database_service.dart';
import '../../auth/state/auth_state.dart';
import '../../vocabulary/models/vocabulary.dart';
import '../models/flashcard_session.dart';

class FlashcardSessionRepository {
  final ApiClient apiClient;
  final LocalDatabaseService localDatabase;
  final Connectivity connectivity;

  FlashcardSessionRepository({
    required this.apiClient,
    required this.localDatabase,
    Connectivity? connectivity,
  }) : connectivity = connectivity ?? Connectivity();

  Future<void> saveResult(FlashcardSessionResult result) async {
    await localDatabase.saveFlashcardSessionResult(result);
    if (result.lessonId == null || result.lessonId!.isEmpty) return;

    final connectivityResults = await connectivity.checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.none)) return;

    try {
      await apiClient.dio.put(
        '/progress',
        data: {
          'lessonId': result.lessonId,
          'lastViewedVocabIndex': result.totalCards,
          'completed': true,
          'score': result.accuracy,
          'practiceType': 'flashcards',
          'lastPracticeAt': result.completedAt.toIso8601String(),
          'totalPracticeScore': result.accuracy,
          'clientUpdatedAt': result.completedAt.toIso8601String(),
        },
      );
      await localDatabase.markFlashcardSessionSynced(result.completedAt);
    } catch (error) {
      if (!_isRetryable(error)) rethrow;
    }
  }

  Future<void> saveResume(
    String sessionKey,
    FlashcardSessionState state,
  ) {
    return localDatabase.saveFlashcardResume(
      sessionKey: sessionKey,
      currentIndex: state.currentIndex,
      statuses: state.statuses.map(
        (id, status) => MapEntry(id, status.name),
      ),
    );
  }

  Future<FlashcardSessionState?> loadResume(
    String sessionKey,
    List<dynamic> cards,
  ) async {
    final vocabulary = cards.whereType<Vocabulary>().toList();
    if (vocabulary.isEmpty) return null;
    final saved = await localDatabase.getFlashcardResume(sessionKey);
    if (saved == null) return null;
    final statuses = saved['statuses'];
    return FlashcardSessionState.resume(
      vocabulary,
      currentIndex: saved['currentIndex'] as int? ?? 0,
      statuses: statuses is Map
          ? statuses.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : const {},
    );
  }

  Future<void> clearResume(String sessionKey) {
    return localDatabase.clearFlashcardResume(sessionKey);
  }

  Future<int> syncPendingResults() async {
    final results = await localDatabase.getFlashcardSessionResults();
    var synced = 0;
    for (final result in results.where((item) => !item.synced)) {
      final lessonId = result.lessonId;
      if (lessonId == null || lessonId.isEmpty) continue;
      try {
        await apiClient.dio.put(
          '/progress',
          data: {
            'lessonId': lessonId,
            'lastViewedVocabIndex': result.totalCards,
            'completed': true,
            'score': result.accuracy,
            'practiceType': 'flashcards',
            'lastPracticeAt': result.completedAt.toIso8601String(),
            'totalPracticeScore': result.accuracy,
            'clientUpdatedAt': result.completedAt.toIso8601String(),
          },
        );
        await localDatabase.markFlashcardSessionSynced(result.completedAt);
        synced += 1;
      } catch (_) {
        // Keep this and remaining results available for a later retry.
      }
    }
    return synced;
  }
}

final flashcardSessionRepositoryProvider =
    FutureProvider<FlashcardSessionRepository>((ref) async {
  return FlashcardSessionRepository(
    apiClient: ref.watch(apiClientProvider),
    localDatabase: await ref.watch(localDatabaseProvider.future),
  );
});

bool _isRetryable(Object error) {
  if (error is! DioException) return false;
  return error.response == null ||
      error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout;
}
