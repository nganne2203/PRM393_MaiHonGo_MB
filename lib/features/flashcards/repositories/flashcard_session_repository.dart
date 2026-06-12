import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/local_database_provider.dart';
import '../../../core/storage/local_database_service.dart';
import '../../auth/state/auth_state.dart';
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
  }
}

final flashcardSessionRepositoryProvider =
    FutureProvider<FlashcardSessionRepository>((ref) async {
  return FlashcardSessionRepository(
    apiClient: ref.watch(apiClientProvider),
    localDatabase: await ref.watch(localDatabaseProvider.future),
  );
});
