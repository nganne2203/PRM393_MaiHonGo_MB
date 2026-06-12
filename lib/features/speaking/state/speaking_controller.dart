import 'package:flutter/foundation.dart';

import '../../../core/media/audio_player_service.dart';
import '../../../core/media/recording_service.dart';
import '../../../core/network/api_client.dart';
import '../repositories/speaking_repository.dart';
import 'speaking_state.dart';

class SpeakingController extends ChangeNotifier {
  final SpeakingRepository repository;
  final RecordingService _recordingService;
  final AudioPlayerService _audioPlayerService;

  SpeakingState _state = const SpeakingState.initial();

  SpeakingController({
    SpeakingRepository? repository,
    RecordingService? recordingService,
    AudioPlayerService? audioPlayerService,
  })  : repository = repository ?? SpeakingRepository(),
        _recordingService = recordingService ?? RecordingService(),
        _audioPlayerService = audioPlayerService ?? AudioPlayerService();

  SpeakingState get state => _state;

  Future<void> loadPrompts(String lessonId, {String? lessonTitle}) async {
    _setState(_state.copyWith(
      status: SpeakingViewStatus.loading,
      selectedLessonId: lessonId,
      selectedLessonName: lessonTitle,
      clearMessage: true,
      clearLatestAttempt: true,
    ));
    try {
      await repository.syncPendingAttempts();
      final prompts = await repository.getPrompts(lessonId);
      _setState(_state.copyWith(
        status: SpeakingViewStatus.ready,
        prompts: prompts,
        selectedIndex: 0,
        selectedLessonId: lessonId,
        selectedLessonName:
            lessonTitle ?? (prompts.isEmpty ? null : prompts.first.lessonTitle),
        message: prompts.isEmpty
            ? 'No speaking exercises are available for this lesson yet.'
            : null,
        clearAudioPath: true,
        clearLatestAttempt: true,
      ));
    } catch (error) {
      final offline = !await repository.isOnline();
      _setState(_state.copyWith(
        status: SpeakingViewStatus.error,
        message: offline
            ? 'Speaking practice is unavailable offline because this lesson has not been downloaded.'
            : ApiClient.describeError(error),
      ));
    }
  }

  void selectPrompt(int index) {
    if (index < 0 || index >= _state.prompts.length) return;
    _setState(_state.copyWith(
      status: SpeakingViewStatus.ready,
      selectedIndex: index,
      clearAudioPath: true,
      clearLatestAttempt: true,
      clearMessage: true,
    ));
  }

  Future<void> startRecording() async {
    try {
      final path = await _recordingService.startRecording();
      _setState(_state.copyWith(
        status: SpeakingViewStatus.recording,
        audioPath: path,
        clearLatestAttempt: true,
        clearMessage: true,
      ));
    } catch (error) {
      _setState(_state.copyWith(
        status: SpeakingViewStatus.error,
        message: error is RecordingException
            ? error.message
            : 'Audio recording failed.',
      ));
    }
  }

  Future<void> stopRecording() async {
    final path = await _recordingService.stopRecording();
    _setState(_state.copyWith(
      status: SpeakingViewStatus.recorded,
      audioPath: path ?? _state.audioPath,
      message: 'Recording ready. Preview or submit it for AI review.',
    ));
  }

  Future<void> previewRecording() async {
    final path = _state.audioPath;
    if (path == null || path.isEmpty) {
      _setState(_state.copyWith(
        status: SpeakingViewStatus.error,
        message: 'Record audio before previewing.',
      ));
      return;
    }
    await _audioPlayerService.playLocalFile(path);
  }

  Future<void> submitRecording(String lessonId) async {
    final prompt = _state.selectedPrompt;
    final audioPath = _state.audioPath;
    if (prompt == null) {
      _setState(_state.copyWith(
        status: SpeakingViewStatus.error,
        message: 'Choose a speaking prompt first.',
      ));
      return;
    }
    if (audioPath == null || audioPath.isEmpty) {
      _setState(_state.copyWith(
        status: SpeakingViewStatus.error,
        message: 'Record audio before submitting.',
      ));
      return;
    }

    _setState(_state.copyWith(
      status: SpeakingViewStatus.submitting,
      clearMessage: true,
      clearLatestAttempt: true,
    ));

    try {
      final attempt = await repository.submitAttempt(
        promptId: prompt.id,
        lessonId: lessonId,
        audioPath: audioPath,
        clientAttemptId: 'speaking-${DateTime.now().microsecondsSinceEpoch}',
        syncSource: 'online',
      );
      _setState(_state.copyWith(
        status: attempt.status == 'pendingSync'
            ? SpeakingViewStatus.offlineQueued
            : SpeakingViewStatus.success,
        latestAttempt: attempt,
        message: attempt.status == 'pendingSync'
            ? 'Your speaking attempt will be evaluated when you are online.'
            : null,
      ));
    } catch (error) {
      _setState(_state.copyWith(
        status: SpeakingViewStatus.error,
        message: ApiClient.describeError(error),
      ));
    }
  }

  @visibleForTesting
  void setStateForTest(SpeakingState state) => _setState(state);

  void _setState(SpeakingState state) {
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _recordingService.dispose();
    _audioPlayerService.dispose();
    super.dispose();
  }
}
