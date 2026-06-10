import '../models/speaking_models.dart';

enum SpeakingViewStatus {
  idle,
  loading,
  ready,
  recording,
  recorded,
  submitting,
  success,
  offlineQueued,
  error,
}

class SpeakingState {
  final SpeakingViewStatus status;
  final List<SpeakingPrompt> prompts;
  final int selectedIndex;
  final String? audioPath;
  final SpeakingAttempt? latestAttempt;
  final String? message;

  const SpeakingState({
    required this.status,
    required this.prompts,
    required this.selectedIndex,
    this.audioPath,
    this.latestAttempt,
    this.message,
  });

  const SpeakingState.initial()
      : status = SpeakingViewStatus.idle,
        prompts = const [],
        selectedIndex = 0,
        audioPath = null,
        latestAttempt = null,
        message = null;

  SpeakingPrompt? get selectedPrompt => prompts.isEmpty
      ? null
      : prompts[selectedIndex.clamp(0, prompts.length - 1).toInt()];

  SpeakingState copyWith({
    SpeakingViewStatus? status,
    List<SpeakingPrompt>? prompts,
    int? selectedIndex,
    String? audioPath,
    bool clearAudioPath = false,
    SpeakingAttempt? latestAttempt,
    bool clearLatestAttempt = false,
    String? message,
    bool clearMessage = false,
  }) =>
      SpeakingState(
        status: status ?? this.status,
        prompts: prompts ?? this.prompts,
        selectedIndex: selectedIndex ?? this.selectedIndex,
        audioPath: clearAudioPath ? null : audioPath ?? this.audioPath,
        latestAttempt:
            clearLatestAttempt ? null : latestAttempt ?? this.latestAttempt,
        message: clearMessage ? null : message ?? this.message,
      );
}
