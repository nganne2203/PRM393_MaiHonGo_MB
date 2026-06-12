import '../models/listening_models.dart';

enum ListeningViewStatus {
  initial,
  loading,
  ready,
  submitting,
  success,
  offlineQueued,
  error,
}

class ListeningState {
  final ListeningViewStatus status;
  final List<ListeningExercise> exercises;
  final int selectedIndex;
  final String? selectedAnswer;
  final ListeningAttempt? latestAttempt;
  final String? message;

  const ListeningState({
    required this.status,
    required this.exercises,
    required this.selectedIndex,
    this.selectedAnswer,
    this.latestAttempt,
    this.message,
  });

  const ListeningState.initial()
      : status = ListeningViewStatus.initial,
        exercises = const [],
        selectedIndex = 0,
        selectedAnswer = null,
        latestAttempt = null,
        message = null;

  ListeningExercise? get selectedExercise =>
      selectedIndex >= 0 && selectedIndex < exercises.length
          ? exercises[selectedIndex]
          : null;

  ListeningState copyWith({
    ListeningViewStatus? status,
    List<ListeningExercise>? exercises,
    int? selectedIndex,
    String? selectedAnswer,
    ListeningAttempt? latestAttempt,
    String? message,
    bool clearSelectedAnswer = false,
    bool clearLatestAttempt = false,
    bool clearMessage = false,
  }) {
    return ListeningState(
      status: status ?? this.status,
      exercises: exercises ?? this.exercises,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      selectedAnswer:
          clearSelectedAnswer ? null : selectedAnswer ?? this.selectedAnswer,
      latestAttempt:
          clearLatestAttempt ? null : latestAttempt ?? this.latestAttempt,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}
