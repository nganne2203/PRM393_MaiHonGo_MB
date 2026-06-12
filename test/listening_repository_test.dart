import 'package:flutter_test/flutter_test.dart';
import 'package:maihongo/features/listening/repositories/listening_repository.dart';

void main() {
  test('ListeningRepository parses exercise envelope', () {
    final exercises = ListeningRepository.parseExerciseListEnvelope({
      'success': true,
      'message': 'ok',
      'data': [
        {
          '_id': 'exercise-1',
          'lessonId': 'lesson-1',
          'title': 'Listen',
          'instruction': 'Choose the word.',
          'audioUrl': 'https://cdn.example.com/listen.mp3',
          'transcript': 'みず',
          'questionText': 'What did you hear?',
          'choices': ['水', '学校'],
          'correctAnswer': '水',
          'explanation': 'みず means water.',
          'difficulty': 'beginner',
        }
      ],
      'pagination': null,
    });

    expect(exercises, hasLength(1));
    expect(exercises.first.id, 'exercise-1');
    expect(exercises.first.audioUrl, 'https://cdn.example.com/listen.mp3');
    expect(exercises.first.choices, ['水', '学校']);
  });

  test('ListeningRepository parses attempt envelope', () {
    final attempt = ListeningRepository.parseAttemptEnvelope({
      'success': true,
      'message': 'saved',
      'data': {
        '_id': 'attempt-1',
        'exerciseId': 'exercise-1',
        'lessonId': 'lesson-1',
        'selectedAnswer': '水',
        'isCorrect': true,
        'score': 100,
        'syncSource': 'online',
        'clientAttemptId': 'client-1',
        'attemptedAt': '2026-06-12T00:00:00.000Z',
      },
      'pagination': null,
    });

    expect(attempt.id, 'attempt-1');
    expect(attempt.isCorrect, isTrue);
    expect(attempt.score, 100);
    expect(attempt.pendingSync, isFalse);
  });
}
