import '../../vocabulary/models/vocabulary.dart';

enum QuizQuestionType {
  multipleChoice,
  typing;

  static QuizQuestionType fromApiValue(String value) {
    return value == 'typing'
        ? QuizQuestionType.typing
        : QuizQuestionType.multipleChoice;
  }

  String get apiValue => switch (this) {
        QuizQuestionType.multipleChoice => 'multiple_choice',
        QuizQuestionType.typing => 'typing',
      };
}

class QuizQuestion {
  final String id;
  final QuizQuestionType type;
  final Vocabulary vocabulary;
  final String prompt;
  final String correctAnswer;
  final List<String> options;

  const QuizQuestion({
    required this.id,
    required this.type,
    required this.vocabulary,
    required this.prompt,
    required this.correctAnswer,
    required this.options,
  });
}

class QuizAnswer {
  final String questionId;
  final QuizQuestionType type;
  final String selectedAnswer;
  final String correctAnswer;
  final bool isCorrect;

  const QuizAnswer({
    required this.questionId,
    required this.type,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.isCorrect,
  });

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'type': type.apiValue,
        'selectedAnswer': selectedAnswer,
        'correctAnswer': correctAnswer,
        'isCorrect': isCorrect,
      };

  factory QuizAnswer.fromJson(Map<String, dynamic> json) => QuizAnswer(
        questionId: json['questionId']?.toString() ?? '',
        type: QuizQuestionType.fromApiValue(json['type']?.toString() ?? ''),
        selectedAnswer: json['selectedAnswer']?.toString() ?? '',
        correctAnswer: json['correctAnswer']?.toString() ?? '',
        isCorrect: json['isCorrect'] == true,
      );
}

class QuizSubmission {
  final String lessonId;
  final int score;
  final int total;
  final int durationSec;
  final List<QuizAnswer> answers;
  final String syncSource;
  final String clientAttemptId;

  const QuizSubmission({
    required this.lessonId,
    required this.score,
    required this.total,
    required this.durationSec,
    required this.answers,
    required this.syncSource,
    required this.clientAttemptId,
  });

  Map<String, dynamic> toJson() => {
        'lessonId': lessonId,
        'score': score,
        'total': total,
        'durationSec': durationSec,
        'answers': answers.map((item) => item.toJson()).toList(),
        'syncSource': syncSource,
        'clientAttemptId': clientAttemptId,
        'type': answers.any((item) => item.type == QuizQuestionType.typing)
            ? 'typing'
            : 'multiple_choice',
      };
}

class QuizResult {
  final String id;
  final String lessonId;
  final int score;
  final int total;
  final int durationSec;
  final String syncSource;
  final String clientAttemptId;
  final bool pendingSync;

  const QuizResult({
    required this.id,
    required this.lessonId,
    required this.score,
    required this.total,
    required this.durationSec,
    required this.syncSource,
    required this.clientAttemptId,
    this.pendingSync = false,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        lessonId: json['lessonId']?.toString() ?? '',
        score: _toInt(json['correctAnswers'] ?? json['score']),
        total: _toInt(json['totalQuestions'] ?? json['total']),
        durationSec: _toInt(json['durationSec']),
        syncSource: json['syncSource']?.toString() ?? 'online',
        clientAttemptId: json['clientResultId']?.toString() ??
            json['clientAttemptId']?.toString() ??
            '',
      );

  factory QuizResult.pending(QuizSubmission submission) => QuizResult(
        id: submission.clientAttemptId,
        lessonId: submission.lessonId,
        score: submission.score,
        total: submission.total,
        durationSec: submission.durationSec,
        syncSource: 'offline',
        clientAttemptId: submission.clientAttemptId,
        pendingSync: true,
      );
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
