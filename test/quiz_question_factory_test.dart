import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maihongo/features/quiz/models/quiz_models.dart';
import 'package:maihongo/features/vocabulary/models/vocabulary.dart';

void main() {
  test('quiz questions are randomized and multiple choice answers are unique',
      () {
    final vocabulary = List.generate(
      8,
      (index) => Vocabulary(
        id: 'v$index',
        word: 'word$index',
        hiragana: 'reading$index',
        romaji: 'romaji$index',
        meaningVi: 'meaning$index',
        examples: const [],
        tags: const [],
      ),
    );

    final questions = QuizQuestionFactory.build(
      vocabulary,
      random: Random(42),
    );
    final choices = questions
        .where((question) => question.type == QuizQuestionType.multipleChoice)
        .toList();

    expect(questions, hasLength(8));
    expect(questions.first.vocabulary.id, isNot('v0'));
    expect(choices, isNotEmpty);
    expect(
      choices.every((question) =>
          question.options.toSet().length == question.options.length &&
          question.options.contains(question.correctAnswer)),
      isTrue,
    );
    expect(
      choices
          .any((question) => question.options.first != question.correctAnswer),
      isTrue,
    );
  });

  test('quiz falls back to typing when choices cannot be built', () {
    const vocabulary = [
      Vocabulary(
        id: 'v1',
        word: '水',
        hiragana: 'みず',
        romaji: 'mizu',
        meaningVi: 'water',
        examples: [],
        tags: [],
      ),
    ];

    final questions = QuizQuestionFactory.build(vocabulary, random: Random(1));

    expect(questions.single.type, QuizQuestionType.typing);
    expect(questions.single.options, isEmpty);
  });
}
