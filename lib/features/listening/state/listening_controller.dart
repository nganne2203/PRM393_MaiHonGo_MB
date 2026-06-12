import 'package:flutter/foundation.dart';

import '../../../core/media/audio_cache_service.dart';
import '../../../core/media/audio_player_service.dart';
import '../../../core/network/api_client.dart';
import '../repositories/listening_repository.dart';
import 'listening_state.dart';

class ListeningController extends ChangeNotifier {
  final ListeningRepository repository;
  final AudioPlayerService audioPlayerService;
  final AudioCacheService audioCacheService;

  ListeningState _state = const ListeningState.initial();

  ListeningController({
    ListeningRepository? repository,
    AudioPlayerService? audioPlayerService,
    AudioCacheService? audioCacheService,
  })  : repository = repository ?? ListeningRepository(),
        audioPlayerService = audioPlayerService ?? AudioPlayerService(),
        audioCacheService = audioCacheService ?? AudioCacheService();

  ListeningState get state => _state;

  Future<void> loadExercises(String lessonId) async {
    _setState(_state.copyWith(
      status: ListeningViewStatus.loading,
      clearMessage: true,
      clearLatestAttempt: true,
      clearSelectedAnswer: true,
    ));
    try {
      await repository.syncPendingAttempts();
      final exercises = await repository.getExercises(lessonId);
      _setState(_state.copyWith(
        status: ListeningViewStatus.ready,
        exercises: exercises,
        selectedIndex: 0,
        message: exercises.isEmpty
            ? 'No listening exercises found for this lesson.'
            : null,
        clearLatestAttempt: true,
        clearSelectedAnswer: true,
      ));
    } catch (error) {
      _setState(_state.copyWith(
        status: ListeningViewStatus.error,
        message: ApiClient.describeError(error),
      ));
    }
  }

  void selectExercise(int index) {
    if (index < 0 || index >= _state.exercises.length) return;
    _setState(_state.copyWith(
      status: ListeningViewStatus.ready,
      selectedIndex: index,
      clearSelectedAnswer: true,
      clearLatestAttempt: true,
      clearMessage: true,
    ));
  }

  void selectAnswer(String answer) {
    _setState(_state.copyWith(selectedAnswer: answer, clearMessage: true));
  }

  Future<void> playCurrentAudio() async {
    final exercise = _state.selectedExercise;
    final url = exercise?.audioUrl.trim() ?? '';
    if (exercise == null || url.isEmpty) {
      _setState(_state.copyWith(message: 'Audio is not available yet.'));
      return;
    }

    try {
      final cachedPath = await audioCacheService.cachedPathForUrl(url);
      if (cachedPath != null) {
        await audioPlayerService.playLocalFile(cachedPath);
        return;
      }
      await audioPlayerService.playUrl(url);
      await audioCacheService.cacheRemoteAudio(url);
    } catch (error) {
      _setState(_state.copyWith(message: ApiClient.describeError(error)));
    }
  }

  Future<void> submitAnswer(String lessonId) async {
    final exercise = _state.selectedExercise;
    final selectedAnswer = _state.selectedAnswer;
    if (exercise == null) {
      _setState(_state.copyWith(message: 'Choose a listening exercise first.'));
      return;
    }
    if (selectedAnswer == null || selectedAnswer.isEmpty) {
      _setState(
          _state.copyWith(message: 'Choose an answer before submitting.'));
      return;
    }

    _setState(_state.copyWith(
      status: ListeningViewStatus.submitting,
      clearMessage: true,
      clearLatestAttempt: true,
    ));

    try {
      final attempt = await repository.submitAttempt(
        exerciseId: exercise.id,
        lessonId: lessonId,
        selectedAnswer: selectedAnswer,
        clientAttemptId: 'listening-${DateTime.now().microsecondsSinceEpoch}',
        syncSource: 'online',
      );
      _setState(_state.copyWith(
        status: attempt.pendingSync
            ? ListeningViewStatus.offlineQueued
            : ListeningViewStatus.success,
        latestAttempt: attempt,
        message: attempt.pendingSync
            ? 'Your listening answer will sync when you are online.'
            : null,
      ));
    } catch (error) {
      _setState(_state.copyWith(
        status: ListeningViewStatus.error,
        message: ApiClient.describeError(error),
      ));
    }
  }

  @visibleForTesting
  void setStateForTest(ListeningState state) => _setState(state);

  void _setState(ListeningState state) {
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    audioPlayerService.dispose();
    super.dispose();
  }
}
