import 'package:flutter_test/flutter_test.dart';
import 'package:maihongo/core/network/api_client.dart';
import 'package:maihongo/features/progress/models/progress_models.dart';
import 'package:maihongo/features/quiz/models/quiz_models.dart';
import 'package:maihongo/features/writing/repositories/writing_repository.dart';

void main() {
  test('quiz answers round-trip through submission JSON', () {
    const answer = QuizAnswer(
      questionId: 'vocab-1',
      type: QuizQuestionType.typing,
      selectedAnswer: 'がっこう',
      correctAnswer: 'がっこう',
      isCorrect: true,
    );

    final submission = QuizSubmission(
      lessonId: 'lesson-1',
      score: 1,
      total: 1,
      durationSec: 12,
      answers: const [answer],
      syncSource: 'online',
      clientAttemptId: 'attempt-1',
    );

    final answers = submission.toJson()['answers'] as List<dynamic>;
    final restored = QuizAnswer.fromJson(asJsonMap(answers.first));

    expect(restored.type, QuizQuestionType.typing);
    expect(restored.selectedAnswer, 'がっこう');
    expect(restored.isCorrect, isTrue);
  });

  test('writing prompt parser keeps populated lesson title user-facing', () {
    final prompts = WritingRepository.parsePromptListEnvelope({
      'success': true,
      'data': [
        {
          '_id': 'prompt-1',
          'lessonId': {'_id': 'lesson-1', 'title': 'JLPT N5 - School'},
          'promptText': 'Write a sentence with 学校',
          'promptType': 'sentence',
        }
      ],
    });

    expect(prompts, hasLength(1));
    expect(prompts.first.lessonId, 'lesson-1');
    expect(prompts.first.lessonTitle, 'JLPT N5 - School');
  });

  test('progress update payload can be restored for offline sync', () {
    final now = DateTime(2026, 6, 12, 11, 30);
    final request = ProgressUpdateRequest(
      lessonId: 'lesson-1',
      lastViewedVocabIndex: 3,
      completed: true,
      score: 80,
      practiceType: 'quiz',
      completedWritingCount: 1,
      totalPracticeScore: 4,
      clientUpdatedAt: now,
    );

    final restored = ProgressUpdateRequest.fromJson(request.toJson());

    expect(restored.lessonId, 'lesson-1');
    expect(restored.practiceType, 'quiz');
    expect(restored.completedWritingCount, 1);
    expect(restored.totalPracticeScore, 4);
    expect(restored.clientUpdatedAt, now);
  });
}
