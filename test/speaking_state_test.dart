import 'package:flutter_test/flutter_test.dart';
import 'package:maihongo/features/speaking/models/speaking_models.dart';
import 'package:maihongo/features/speaking/state/speaking_state.dart';

void main() {
  test('SpeakingState transitions from loading to ready with selected prompt',
      () {
    const prompt = SpeakingPrompt(
      id: 'prompt-1',
      lessonId: 'lesson-1',
      promptText: 'Please say this sentence',
      expectedText: 'にほんごをべんきょうします',
      expectedReading: 'nihongo wo benkyo shimasu',
      sampleAudioUrl: '',
      difficulty: 'beginner',
    );

    final loading = const SpeakingState.initial().copyWith(
      status: SpeakingViewStatus.loading,
    );
    final ready = loading.copyWith(
      status: SpeakingViewStatus.ready,
      prompts: [prompt],
    );

    expect(loading.status, SpeakingViewStatus.loading);
    expect(ready.status, SpeakingViewStatus.ready);
    expect(ready.selectedPrompt?.expectedText, 'にほんごをべんきょうします');
  });
}
