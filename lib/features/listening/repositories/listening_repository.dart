import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/local_database_service.dart';
import '../data/listening_local_store.dart';
import '../models/listening_models.dart';

class ListeningRepository {
  final ApiClient apiClient;
  final ListeningLocalStore localStore;
  final Connectivity connectivity;
  final Future<LocalDatabaseService>? _localDatabase;

  ListeningRepository({
    ApiClient? apiClient,
    ListeningLocalStore? localStore,
    Connectivity? connectivity,
    Future<LocalDatabaseService>? localDatabase,
  })  : apiClient = apiClient ?? ApiClient(),
        localStore = localStore ?? ListeningLocalStore(),
        connectivity = connectivity ?? Connectivity(),
        _localDatabase = localDatabase ?? LocalDatabaseService.open();

  Future<List<ListeningExercise>> getExercises(String lessonId) async {
    try {
      final response = await apiClient.dio.get(
        '/listening/exercises',
        queryParameters: lessonId.isEmpty ? null : {'lessonId': lessonId},
      );
      final exercises = parseExerciseListEnvelope(asJsonMap(response.data));
      if (lessonId.isNotEmpty) {
        await _saveCachedExercises(lessonId, exercises);
      }
      return exercises;
    } catch (_) {
      final cached = await _readCachedExercises(lessonId);
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  Future<ListeningExercise> getExercise(String id) async {
    final response = await apiClient.dio.get('/listening/exercises/$id');
    final data = ApiEnvelope.unwrapData(asJsonMap(response.data));
    if (data is! Map) {
      throw const ApiException('Listening exercise response is invalid.');
    }
    return ListeningExercise.fromJson(asJsonMap(data));
  }

  Future<ListeningAttempt> submitAttempt({
    required String exerciseId,
    required String lessonId,
    required String selectedAnswer,
    required String clientAttemptId,
    required String syncSource,
  }) async {
    if (!await isOnline()) {
      final pending = PendingListeningAttempt(
        exerciseId: exerciseId,
        lessonId: lessonId,
        selectedAnswer: selectedAnswer,
        clientAttemptId: clientAttemptId,
        syncSource: 'offline',
        createdAt: DateTime.now(),
      );
      await localStore.addPendingAttempt(pending);
      return ListeningAttempt.pendingSync(pending);
    }

    try {
      return await _submitAttempt(
        exerciseId: exerciseId,
        lessonId: lessonId,
        selectedAnswer: selectedAnswer,
        clientAttemptId: clientAttemptId,
        syncSource: syncSource,
      );
    } catch (error) {
      if (!_isRetryable(error)) rethrow;
      final pending = PendingListeningAttempt(
        exerciseId: exerciseId,
        lessonId: lessonId,
        selectedAnswer: selectedAnswer,
        clientAttemptId: clientAttemptId,
        syncSource: 'offline',
        createdAt: DateTime.now(),
      );
      await localStore.addPendingAttempt(pending);
      return ListeningAttempt.pendingSync(pending);
    }
  }

  Future<void> _saveCachedExercises(
    String lessonId,
    List<ListeningExercise> exercises,
  ) async {
    try {
      final database = await _localDatabase;
      await database?.savePracticeContent(
        kind: 'listening',
        lessonId: lessonId,
        items: exercises.map(_exerciseToJson).toList(),
      );
    } catch (_) {}
  }

  Future<List<ListeningExercise>> _readCachedExercises(String lessonId) async {
    if (lessonId.isEmpty) return const [];
    try {
      final database = await _localDatabase;
      final items = await database?.getPracticeContent(
            kind: 'listening',
            lessonId: lessonId,
          ) ??
          const [];
      return items.map(ListeningExercise.fromJson).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<ListeningAttempt>> getAttempts({String? lessonId}) async {
    final path = lessonId == null || lessonId.isEmpty
        ? '/listening/attempts'
        : '/listening/attempts/$lessonId';
    final pending = await localStore.loadPendingAttempts();
    final filteredPending = lessonId == null || lessonId.isEmpty
        ? pending
        : pending.where((item) => item.lessonId == lessonId);
    try {
      final response = await apiClient.dio.get(path);
      final remote = parseAttemptListEnvelope(asJsonMap(response.data));
      return [
        ...filteredPending.map(ListeningAttempt.pendingSync),
        ...remote,
      ];
    } catch (_) {
      if (filteredPending.isNotEmpty) {
        return filteredPending.map(ListeningAttempt.pendingSync).toList();
      }
      rethrow;
    }
  }

  Future<List<ListeningAttempt>> syncPendingAttempts() async {
    if (!await isOnline()) return [];

    final synced = <ListeningAttempt>[];
    final pendingAttempts = await localStore.loadPendingAttempts();
    for (final pending in pendingAttempts) {
      try {
        final attempt = await _submitAttempt(
          exerciseId: pending.exerciseId,
          lessonId: pending.lessonId,
          selectedAnswer: pending.selectedAnswer,
          clientAttemptId: pending.clientAttemptId,
          syncSource: 'offline',
        );
        await localStore.removePendingAttempt(pending.clientAttemptId);
        synced.add(attempt);
      } catch (_) {
        // Keep failed items queued for a later sync.
      }
    }
    return synced;
  }

  Future<bool> isOnline() async {
    final results = await connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  Future<ListeningAttempt> _submitAttempt({
    required String exerciseId,
    required String lessonId,
    required String selectedAnswer,
    required String clientAttemptId,
    required String syncSource,
  }) async {
    final response = await apiClient.dio.post(
      '/listening/attempts',
      data: {
        'exerciseId': exerciseId,
        'lessonId': lessonId,
        'selectedAnswer': selectedAnswer,
        'clientAttemptId': clientAttemptId,
        'syncSource': syncSource,
      },
    );
    return parseAttemptEnvelope(asJsonMap(response.data));
  }

  static List<ListeningExercise> parseExerciseListEnvelope(
    Map<String, dynamic> envelope,
  ) {
    final data = ApiEnvelope.unwrapData(envelope);
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((item) => ListeningExercise.fromJson(asJsonMap(item)))
        .toList();
  }

  static ListeningAttempt parseAttemptEnvelope(Map<String, dynamic> envelope) {
    final data = ApiEnvelope.unwrapData(envelope);
    if (data is! Map) {
      throw const ApiException('Listening attempt response is invalid.');
    }
    return ListeningAttempt.fromJson(asJsonMap(data));
  }

  static List<ListeningAttempt> parseAttemptListEnvelope(
    Map<String, dynamic> envelope,
  ) {
    final data = ApiEnvelope.unwrapData(envelope);
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((item) => ListeningAttempt.fromJson(asJsonMap(item)))
        .toList();
  }
}

Map<String, dynamic> _exerciseToJson(ListeningExercise exercise) => {
      '_id': exercise.id,
      'lessonId': exercise.lessonId,
      'vocabId': exercise.vocabId,
      'title': exercise.title,
      'instruction': exercise.instruction,
      'audioUrl': exercise.audioUrl,
      'transcript': exercise.transcript,
      'questionText': exercise.questionText,
      'choices': exercise.choices,
      'correctAnswer': exercise.correctAnswer,
      'explanation': exercise.explanation,
      'difficulty': exercise.difficulty,
    };

bool _isRetryable(Object error) {
  if (error is! DioException) return false;
  return error.response == null ||
      error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout;
}
