import 'package:flutter_test/flutter_test.dart';
import 'package:maihongo/features/speaking/repositories/speaking_repository.dart';

void main() {
  test('SpeakingRepository parses prompt response envelope', () {
    final prompts = SpeakingRepository.parsePromptListEnvelope({
      'success': true,
      'message': 'ok',
      'pagination': null,
      'data': [
        {
          '_id': 'prompt-1',
          'lessonId': 'lesson-1',
          'promptText': 'Please say this sentence',
          'expectedText': 'これはほんです',
          'expectedReading': 'kore wa hon desu',
          'sampleAudioUrl': '',
          'difficulty': 'beginner',
        }
      ],
    });

    expect(prompts, hasLength(1));
    expect(prompts.first.expectedText, 'これはほんです');
  });

  test('SpeakingRepository parses attempt response envelope', () {
    final attempt = SpeakingRepository.parseAttemptEnvelope({
      'success': true,
      'message': 'ok',
      'pagination': null,
      'data': {
        '_id': 'attempt-1',
        'promptId': 'prompt-1',
        'lessonId': 'lesson-1',
        'status': 'pendingSync',
        'feedback': 'Queued.',
      },
    });

    expect(attempt.id, 'attempt-1');
    expect(attempt.status, 'pendingSync');
  });
}
