import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../../core/network/api_client.dart';
import '../repositories/speaking_repository.dart';
import 'speaking_state.dart';

class SpeakingController extends ChangeNotifier {
  final SpeakingRepository repository;
  final AudioRecorder _recorder;
  final AudioPlayer _player;

  SpeakingState _state = const SpeakingState.initial();

  SpeakingController({
    SpeakingRepository? repository,
    AudioRecorder? recorder,
    AudioPlayer? player,
  })  : repository = repository ?? SpeakingRepository(),
        _recorder = recorder ?? AudioRecorder(),
        _player = player ?? AudioPlayer();

  SpeakingState get state => _state;

  Future<void> loadPrompts(String lessonId) async {
    _setState(_state.copyWith(
      status: SpeakingViewStatus.loading,
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
        message: prompts.isEmpty
            ? 'No speaking prompts found for this lesson.'
            : null,
        clearAudioPath: true,
        clearLatestAttempt: true,
      ));
    } catch (error) {
      _setState(_state.copyWith(
        status: SpeakingViewStatus.error,
        message: ApiClient.describeError(error),
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
    final permission = await Permission.microphone.request();
    if (!permission.isGranted || !await _recorder.hasPermission()) {
      _setState(_state.copyWith(
        status: SpeakingViewStatus.error,
        message: 'Microphone permission denied.',
      ));
      return;
    }

    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/speaking-${DateTime.now().microsecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    _setState(_state.copyWith(
      status: SpeakingViewStatus.recording,
      audioPath: path,
      clearLatestAttempt: true,
      clearMessage: true,
    ));
  }

  Future<void> stopRecording() async {
    final path = await _recorder.stop();
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
    await _player.setFilePath(path);
    await _player.play();
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
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }
}
