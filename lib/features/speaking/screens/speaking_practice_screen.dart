import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../state/speaking_controller.dart';
import '../state/speaking_state.dart';
import '../widgets/speaking_result_card.dart';
import 'speaking_history_screen.dart';

class SpeakingPracticeScreen extends StatefulWidget {
  static const defaultLessonId = String.fromEnvironment(
    'SPEAKING_LESSON_ID',
    defaultValue: '',
  );

  const SpeakingPracticeScreen({super.key});

  @override
  State<SpeakingPracticeScreen> createState() => _SpeakingPracticeScreenState();
}

class _SpeakingPracticeScreenState extends State<SpeakingPracticeScreen> {
  late final SpeakingController _controller;
  late final TextEditingController _lessonController;

  @override
  void initState() {
    super.initState();
    _controller = SpeakingController();
    _lessonController = TextEditingController(
      text: SpeakingPracticeScreen.defaultLessonId,
    );
    if (_lessonController.text.isNotEmpty) {
      _controller.loadPrompts(_lessonController.text.trim());
    }
  }

  @override
  void dispose() {
    _lessonController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('Speaking Practice'),
        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SpeakingHistoryScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              _lessonLoader(),
              const SizedBox(height: 16),
              if (_controller.state.status == SpeakingViewStatus.loading)
                const Center(child: CircularProgressIndicator())
              else
                _practiceBody(_controller.state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lessonLoader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _lessonController,
              decoration: const InputDecoration(
                labelText: 'Lesson ID',
                hintText: 'Paste a backend lesson id',
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            tooltip: 'Load prompts',
            onPressed: () =>
                _controller.loadPrompts(_lessonController.text.trim()),
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
    );
  }

  Widget _practiceBody(SpeakingState state) {
    final prompt = state.selectedPrompt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.message != null) _message(state),
        if (prompt != null) ...[
          _promptCard(state),
          const SizedBox(height: 16),
          _recordingControls(state),
        ] else
          _emptyCard(),
        if (state.latestAttempt != null) ...[
          const SizedBox(height: 16),
          SpeakingResultCard(
            attempt: state.latestAttempt!,
            onRetry: () => _controller.selectPrompt(state.selectedIndex),
          ),
        ],
      ],
    );
  }

  Widget _promptCard(SpeakingState state) {
    final prompt = state.selectedPrompt!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.elevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prompt ${state.selectedIndex + 1} of ${state.prompts.length}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            prompt.promptText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            prompt.expectedText,
            style:
                AppTextStyles.jp(30, color: Colors.white, w: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            prompt.expectedReading,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                onPressed: state.selectedIndex == 0
                    ? null
                    : () => _controller.selectPrompt(state.selectedIndex - 1),
                icon: const Icon(Icons.chevron_left_rounded),
                label: const Text('Previous'),
              ),
              const Spacer(),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                onPressed: state.selectedIndex >= state.prompts.length - 1
                    ? null
                    : () => _controller.selectPrompt(state.selectedIndex + 1),
                icon: const Icon(Icons.chevron_right_rounded),
                label: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recordingControls(SpeakingState state) {
    final isRecording = state.status == SpeakingViewStatus.recording;
    final isSubmitting = state.status == SpeakingViewStatus.submitting;
    final hasRecording = state.audioPath != null && state.audioPath!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
            size: 56,
            color: isRecording ? AppColors.sakura : AppColors.primary,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: isSubmitting
                ? null
                : isRecording
                    ? _controller.stopRecording
                    : _controller.startRecording,
            icon: Icon(isRecording ? Icons.stop_rounded : Icons.mic_rounded),
            label: Text(isRecording ? 'Stop recording' : 'Start recording'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hasRecording && !isRecording
                      ? _controller.previewRecording
                      : null,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Preview'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: hasRecording && !isRecording && !isSubmitting
                      ? () => _controller
                          .submitRecording(_lessonController.text.trim())
                      : null,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_rounded),
                  label: Text(isSubmitting ? 'Evaluating' : 'Submit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _message(SpeakingState state) {
    final isError = state.status == SpeakingViewStatus.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isError ? AppColors.sakura : AppColors.gold)
            .withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        state.message!,
        style: TextStyle(
          color: isError ? AppColors.sakura : AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _emptyCard() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Text(
          'Load a lesson to begin speaking practice.',
          style: AppTextStyles.body,
        ),
      );
}
