import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../core/network/api_client.dart';
import '../data/listening_local_store.dart';
import '../models/listening_models.dart';

class ListeningRepository {
  final ApiClient apiClient;
  final ListeningLocalStore localStore;
  final Connectivity connectivity;

  ListeningRepository({
    ApiClient? apiClient,
    ListeningLocalStore? localStore,
    Connectivity? connectivity,
  })  : apiClient = apiClient ?? ApiClient(),
        localStore = localStore ?? ListeningLocalStore(),
        connectivity = connectivity ?? Connectivity();

  Future<List<ListeningExercise>> getExercises(String lessonId) async {
    final response = await apiClient.dio.get(
      '/listening/exercises',
      queryParameters: lessonId.isEmpty ? null : {'lessonId': lessonId},
    );
    return parseExerciseListEnvelope(asJsonMap(response.data));
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

    return _submitAttempt(
      exerciseId: exerciseId,
      lessonId: lessonId,
      selectedAnswer: selectedAnswer,
      clientAttemptId: clientAttemptId,
      syncSource: syncSource,
    );
  }

  Future<List<ListeningAttempt>> getAttempts({String? lessonId}) async {
    final path = lessonId == null || lessonId.isEmpty
        ? '/listening/attempts'
        : '/listening/attempts/$lessonId';
    final response = await apiClient.dio.get(path);
    final remote = parseAttemptListEnvelope(asJsonMap(response.data));
    final pending = await localStore.loadPendingAttempts();
    final filteredPending = lessonId == null || lessonId.isEmpty
        ? pending
        : pending.where((item) => item.lessonId == lessonId);
    return [
      ...filteredPending.map(ListeningAttempt.pendingSync),
      ...remote,
    ];
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
