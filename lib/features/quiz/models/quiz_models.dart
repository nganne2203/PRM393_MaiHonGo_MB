import 'dart:math';

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

class QuizQuestionFactory {
  const QuizQuestionFactory._();

  static List<QuizQuestion> build(
    List<Vocabulary> vocabulary, {
    int maxQuestions = 10,
    Random? random,
  }) {
    final generator = random ?? Random();
    final usable = vocabulary
        .where((item) => item.id.isNotEmpty && item.meaningVi.trim().isNotEmpty)
        .toList()
      ..shuffle(generator);
    if (usable.isEmpty) return const [];

    final uniqueMeanings = usable
        .map((item) => item.meaningVi.trim())
        .where((meaning) => meaning.isNotEmpty)
        .toSet()
        .toList();
    final limit = min(maxQuestions, usable.length);

    return List.generate(limit, (index) {
      final vocab = usable[index];
      final canBuildChoices = uniqueMeanings.length > 1;
      final isTyping = index.isOdd || !canBuildChoices;
      return QuizQuestion(
        id: vocab.id,
        type: isTyping
            ? QuizQuestionType.typing
            : QuizQuestionType.multipleChoice,
        vocabulary: vocab,
        prompt: isTyping ? 'TYPE THE READING' : 'WHAT DOES THIS MEAN?',
        correctAnswer: isTyping ? vocab.hiragana : vocab.meaningVi,
        options: isTyping
            ? const []
            : _optionsFor(vocab.meaningVi.trim(), uniqueMeanings, generator),
      );
    });
  }

  static List<String> _optionsFor(
    String correct,
    List<String> meanings,
    Random random,
  ) {
    final distractors = meanings.where((item) => item != correct).toList()
      ..shuffle(random);
    final options = <String>[correct, ...distractors.take(3)]..shuffle(random);
    return options;
  }
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
