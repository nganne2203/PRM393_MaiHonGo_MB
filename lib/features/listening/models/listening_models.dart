class ListeningExercise {
  final String id;
  final String lessonId;
  final String? vocabId;
  final String title;
  final String instruction;
  final String audioUrl;
  final String transcript;
  final String questionText;
  final List<String> choices;
  final String correctAnswer;
  final String explanation;
  final String difficulty;

  const ListeningExercise({
    required this.id,
    required this.lessonId,
    this.vocabId,
    required this.title,
    required this.instruction,
    required this.audioUrl,
    required this.transcript,
    required this.questionText,
    required this.choices,
    required this.correctAnswer,
    required this.explanation,
    required this.difficulty,
  });

  factory ListeningExercise.fromJson(Map<String, dynamic> json) =>
      ListeningExercise(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        lessonId: json['lessonId']?.toString() ?? '',
        vocabId: json['vocabId']?.toString(),
        title: json['title']?.toString() ?? '',
        instruction: json['instruction']?.toString() ?? '',
        audioUrl: json['audioUrl']?.toString() ?? '',
        transcript: json['transcript']?.toString() ?? '',
        questionText: json['questionText']?.toString() ?? '',
        choices: _toStringList(json['choices']),
        correctAnswer: json['correctAnswer']?.toString() ?? '',
        explanation: json['explanation']?.toString() ?? '',
        difficulty: json['difficulty']?.toString() ?? 'beginner',
      );
}

class ListeningAttempt {
  final String id;
  final String exerciseId;
  final String lessonId;
  final String selectedAnswer;
  final bool isCorrect;
  final int score;
  final String syncSource;
  final String clientAttemptId;
  final DateTime? attemptedAt;
  final bool pendingSync;

  const ListeningAttempt({
    required this.id,
    required this.exerciseId,
    required this.lessonId,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.score,
    required this.syncSource,
    required this.clientAttemptId,
    required this.attemptedAt,
    this.pendingSync = false,
  });

  factory ListeningAttempt.fromJson(Map<String, dynamic> json) =>
      ListeningAttempt(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        exerciseId: json['exerciseId']?.toString() ?? '',
        lessonId: json['lessonId']?.toString() ?? '',
        selectedAnswer: json['selectedAnswer']?.toString() ?? '',
        isCorrect: json['isCorrect'] == true,
        score: _toInt(json['score']),
        syncSource: json['syncSource']?.toString() ?? 'online',
        clientAttemptId: json['clientAttemptId']?.toString() ?? '',
        attemptedAt: DateTime.tryParse(json['attemptedAt']?.toString() ?? ''),
      );

  factory ListeningAttempt.pendingSync(PendingListeningAttempt pending) =>
      ListeningAttempt(
        id: pending.clientAttemptId,
        exerciseId: pending.exerciseId,
        lessonId: pending.lessonId,
        selectedAnswer: pending.selectedAnswer,
        isCorrect: false,
        score: 0,
        syncSource: 'offline',
        clientAttemptId: pending.clientAttemptId,
        attemptedAt: pending.createdAt,
        pendingSync: true,
      );
}

class PendingListeningAttempt {
  final String exerciseId;
  final String lessonId;
  final String selectedAnswer;
  final String clientAttemptId;
  final String syncSource;
  final DateTime createdAt;

  const PendingListeningAttempt({
    required this.exerciseId,
    required this.lessonId,
    required this.selectedAnswer,
    required this.clientAttemptId,
    required this.syncSource,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'lessonId': lessonId,
        'selectedAnswer': selectedAnswer,
        'clientAttemptId': clientAttemptId,
        'syncSource': syncSource,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PendingListeningAttempt.fromJson(Map<String, dynamic> json) =>
      PendingListeningAttempt(
        exerciseId: json['exerciseId']?.toString() ?? '',
        lessonId: json['lessonId']?.toString() ?? '',
        selectedAnswer: json['selectedAnswer']?.toString() ?? '',
        clientAttemptId: json['clientAttemptId']?.toString() ?? '',
        syncSource: json['syncSource']?.toString() ?? 'offline',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}

List<String> _toStringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
