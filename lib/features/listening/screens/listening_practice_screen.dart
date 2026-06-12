import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../state/listening_controller.dart';
import '../state/listening_state.dart';

class ListeningPracticeScreen extends StatefulWidget {
  static const defaultLessonId = String.fromEnvironment(
    'LISTENING_LESSON_ID',
    defaultValue: '',
  );

  final String? lessonId;

  const ListeningPracticeScreen({
    super.key,
    this.lessonId,
  });

  @override
  State<ListeningPracticeScreen> createState() =>
      _ListeningPracticeScreenState();
}

class _ListeningPracticeScreenState extends State<ListeningPracticeScreen> {
  late final ListeningController _controller;
  late final TextEditingController _lessonController;

  @override
  void initState() {
    super.initState();
    _controller = ListeningController();
    _lessonController = TextEditingController(
      text: widget.lessonId?.isNotEmpty == true
          ? widget.lessonId!
          : ListeningPracticeScreen.defaultLessonId,
    );
    if (_lessonController.text.isNotEmpty) {
      _controller.loadExercises(_lessonController.text.trim());
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
        title: const Text('Listening Practice'),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              _lessonLoader(),
              const SizedBox(height: 16),
              if (_controller.state.status == ListeningViewStatus.loading)
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
            tooltip: 'Load exercises',
            onPressed: () =>
                _controller.loadExercises(_lessonController.text.trim()),
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
    );
  }

  Widget _practiceBody(ListeningState state) {
    final exercise = state.selectedExercise;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.message != null) _message(state),
        if (exercise != null) ...[
          _exerciseCard(state),
          const SizedBox(height: 16),
          _choiceCard(state),
        ] else
          _emptyCard(),
      ],
    );
  }

  Widget _exerciseCard(ListeningState state) {
    final exercise = state.selectedExercise!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.sky,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exercise ${state.selectedIndex + 1} of ${state.exercises.length}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            exercise.title.isEmpty ? 'Listen and choose' : exercise.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            exercise.instruction.isEmpty
                ? 'Play the audio, then select the matching answer.'
                : exercise.instruction,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.sky,
            ),
            onPressed: _controller.playCurrentAudio,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Play audio'),
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
                    : () => _controller.selectExercise(state.selectedIndex - 1),
                icon: const Icon(Icons.chevron_left_rounded),
                label: const Text('Previous'),
              ),
              const Spacer(),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                onPressed: state.selectedIndex >= state.exercises.length - 1
                    ? null
                    : () => _controller.selectExercise(state.selectedIndex + 1),
                icon: const Icon(Icons.chevron_right_rounded),
                label: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _choiceCard(ListeningState state) {
    final exercise = state.selectedExercise!;
    final attempt = state.latestAttempt;
    final isSubmitting = state.status == ListeningViewStatus.submitting;

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
          Text(exercise.questionText, style: AppTextStyles.h3),
          const SizedBox(height: 14),
          for (final choice in exercise.choices) ...[
            _choiceTile(choice, state),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: isSubmitting
                ? null
                : () => _controller.submitAnswer(_lessonController.text.trim()),
            icon: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(isSubmitting ? 'Submitting' : 'Submit answer'),
          ),
          if (attempt != null) ...[
            const SizedBox(height: 14),
            _result(attempt.isCorrect, exercise.explanation),
          ],
        ],
      ),
    );
  }

  Widget _choiceTile(String choice, ListeningState state) {
    final selected = state.selectedAnswer == choice;
    return InkWell(
      onTap: () => _controller.selectAnswer(choice),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.line,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : AppColors.mute,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(choice, style: AppTextStyles.body)),
          ],
        ),
      ),
    );
  }

  Widget _result(bool isCorrect, String explanation) {
    final color = isCorrect ? AppColors.matcha : AppColors.sakura;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        [
          isCorrect ? 'Correct.' : 'Not quite.',
          if (explanation.isNotEmpty) explanation,
        ].join(' '),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _message(ListeningState state) {
    final isError = state.status == ListeningViewStatus.error;
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
          'Load a lesson to begin listening practice.',
          style: AppTextStyles.body,
        ),
      );
}
