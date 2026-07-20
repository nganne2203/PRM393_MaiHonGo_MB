import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_database_service.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/tokens.dart';
import '../../lessons/models/lesson.dart';
import '../../lessons/repositories/lesson_repository.dart';
import '../state/listening_controller.dart';
import '../state/listening_state.dart';

class ListeningPracticeArgs {
  final String? lessonId;
  final String? lessonTitle;

  const ListeningPracticeArgs({
    this.lessonId,
    this.lessonTitle,
  });
}

class ListeningPracticeScreen extends StatefulWidget {
  static const defaultLessonId = String.fromEnvironment(
    'LISTENING_LESSON_ID',
    defaultValue: '',
  );

  final String? lessonId;
  final String? lessonTitle;

  const ListeningPracticeScreen({
    super.key,
    this.lessonId,
    this.lessonTitle,
  });

  @override
  State<ListeningPracticeScreen> createState() =>
      _ListeningPracticeScreenState();
}

class _ListeningPracticeScreenState extends State<ListeningPracticeScreen> {
  late final ListeningController _controller;
  final _apiClient = ApiClient();
  List<Lesson> _lessons = const [];
  Lesson? _selectedLesson;
  String? _selectedLessonId;
  bool _loadingLessons = false;
  String? _lessonMessage;

  String get _initialLessonId => widget.lessonId?.isNotEmpty == true
      ? widget.lessonId!
      : ListeningPracticeScreen.defaultLessonId;

  @override
  void initState() {
    super.initState();
    _controller = ListeningController();
    if (_initialLessonId.isNotEmpty) {
      _selectedLessonId = _initialLessonId;
      _controller.loadExercises(_initialLessonId);
    }
    _bootstrapLessons();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('Listening Practice')),
            if ((_selectedLesson?.title ?? widget.lessonTitle ?? '').isNotEmpty)
              Text(
                _selectedLesson?.title ?? widget.lessonTitle!,
                style: context.captionText,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
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
    final locked = _initialLessonId.isNotEmpty;
    final title = _selectedLesson?.title ?? widget.lessonTitle;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('Lesson'), style: context.captionText),
          const SizedBox(height: 8),
          if (locked)
            Text(
              title?.isNotEmpty == true ? title! : context.tr('Current lesson'),
              style: context.h3,
              overflow: TextOverflow.ellipsis,
            )
          else if (_loadingLessons)
            const LinearProgressIndicator(minHeight: 4)
          else if (_lessons.isEmpty)
            Text(
              context.tr(
                _lessonMessage ??
                    'Select a lesson to start listening practice.',
              ),
              style: context.bodyText,
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _lessons.any((item) => item.id == _selectedLessonId)
                  ? _selectedLessonId
                  : null,
              decoration: InputDecoration(
                labelText: context.tr('Select Lesson'),
              ),
              items: [
                for (final lesson in _lessons)
                  DropdownMenuItem(
                    value: lesson.id,
                    child: Text(
                      lesson.title.isEmpty
                          ? context.tr('Untitled lesson')
                          : [
                              lesson.title,
                              if (lesson.category.isNotEmpty) lesson.category,
                            ].join(' · '),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (lessonId) {
                final lesson = _lessons
                    .where((item) => item.id == lessonId)
                    .cast<Lesson?>()
                    .firstOrNull;
                if (lesson == null) return;
                _selectLesson(lesson);
              },
            ),
          if (_lessonMessage != null && !_loadingLessons && _lessons.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child:
                  Text(context.tr(_lessonMessage!), style: context.captionText),
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
            context.l10n.isVietnamese
                ? 'Bài ${state.selectedIndex + 1} / ${state.exercises.length}'
                : 'Exercise ${state.selectedIndex + 1} of ${state.exercises.length}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            exercise.title.isEmpty
                ? context.tr('Listen and choose')
                : exercise.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            exercise.instruction.isEmpty
                ? context.tr('Play the audio, then select the matching answer.')
                : exercise.instruction,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.sky,
            ),
            onPressed: exercise.audioUrl.trim().isEmpty
                ? null
                : _controller.playCurrentAudio,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(context.tr(
              exercise.audioUrl.trim().isEmpty
                  ? 'Audio unavailable'
                  : 'Play audio',
            )),
          ),
          const SizedBox(height: 12),
          SegmentedButton<double>(
            segments: const [
              ButtonSegment(value: 0.75, label: Text('0.75x')),
              ButtonSegment(value: 1, label: Text('1x')),
              ButtonSegment(value: 1.25, label: Text('1.25x')),
            ],
            selected: {_controller.playbackSpeed},
            onSelectionChanged: (selection) {
              _controller.setPlaybackSpeed(selection.first);
            },
            showSelectedIcon: false,
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
                label: Text(context.tr('Previous')),
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
                label: Text(context.tr('Next')),
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
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(exercise.questionText, style: context.h3),
          const SizedBox(height: 14),
          for (final choice in exercise.choices) ...[
            _choiceTile(choice, state),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: isSubmitting
                ? null
                : () => _controller.submitAnswer(_selectedLessonId ?? ''),
            icon: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label:
                Text(context.tr(isSubmitting ? 'Submitting' : 'Submit answer')),
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
          color: selected ? AppColors.primarySoft : context.colors.input,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.primary : context.colors.line,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : context.colors.mute,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(choice, style: context.bodyText)),
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
          context.tr(isCorrect ? 'Correct.' : 'Not quite.'),
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
          color: isError ? AppColors.sakura : context.colors.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _emptyCard() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Text(
          context.tr('Load a lesson to begin listening practice.'),
          style: context.bodyText,
        ),
      );

  Future<void> _bootstrapLessons() async {
    setState(() {
      _loadingLessons = true;
      _lessonMessage = null;
    });

    try {
      final repository = LessonRepository(
        apiClient: _apiClient,
        localDatabase: await LocalDatabaseService.open(),
      );
      final result = await repository.getLessons();
      final lessons = result.data;
      if (!mounted) return;

      final selected = _selectedLessonId == null
          ? null
          : lessons.where((item) => item.id == _selectedLessonId).firstOrNull;
      setState(() {
        _lessons = lessons;
        _selectedLesson = selected;
        _loadingLessons = false;
        _lessonMessage = lessons.isEmpty
            ? result.errorMessage ??
                'Select a lesson to start listening practice.'
            : result.isOffline
                ? 'Offline lessons loaded from this device.'
                : null;
      });

      if (_selectedLessonId == null && lessons.length == 1) {
        _selectLesson(lessons.first);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingLessons = false;
        _lessonMessage = 'No lessons are available on this device yet.';
      });
    }
  }

  Future<void> _selectLesson(Lesson lesson) async {
    setState(() {
      _selectedLesson = lesson;
      _selectedLessonId = lesson.id;
      _lessonMessage = null;
    });
    await _controller.loadExercises(lesson.id);
  }
}
