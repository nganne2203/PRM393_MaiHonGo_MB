import 'package:flutter_test/flutter_test.dart';
import 'package:maihongo/features/speaking/models/speaking_models.dart';

void main() {
  test('SpeakingAttempt parses backend evaluation fields', () {
    final attempt = SpeakingAttempt.fromJson({
      '_id': 'attempt-1',
      'promptId': {
        '_id': 'prompt-1',
        'promptText': 'Please say this sentence',
      },
      'lessonId': 'lesson-1',
      'recordingUrl': '/uploads/speaking/audio.m4a',
      'transcript': 'わたしはがくせいです',
      'expectedText': 'わたしはがくせいです',
      'similarityScore': 100,
      'pronunciationScore': 100,
      'feedback': 'Great job.',
      'correctWords': ['わたし', 'は', 'がくせい', 'です'],
      'wrongWords': [],
      'status': 'evaluated',
      'clientAttemptId': 'mobile-1',
      'attemptedAt': '2026-06-09T00:00:00.000Z',
    });

    expect(attempt.id, 'attempt-1');
    expect(attempt.promptId, 'prompt-1');
    expect(attempt.similarityScore, 100);
    expect(attempt.correctWords, contains('がくせい'));
    expect(attempt.status, 'evaluated');
  });
}
