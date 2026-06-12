import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../lessons/models/lesson.dart';
import '../../lessons/repositories/lesson_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../state/speaking_controller.dart';
import '../state/speaking_state.dart';
import '../widgets/speaking_result_card.dart';
import 'speaking_history_screen.dart';

class SpeakingPracticeArgs {
  final String? lessonId;
  final String? lessonTitle;

  const SpeakingPracticeArgs({
    this.lessonId,
    this.lessonTitle,
  });
}

class SpeakingPracticeScreen extends StatefulWidget {
  final String? lessonId;
  final String? lessonTitle;

  const SpeakingPracticeScreen({
    super.key,
    this.lessonId,
    this.lessonTitle,
  });

  @override
  State<SpeakingPracticeScreen> createState() => _SpeakingPracticeScreenState();
}

class _SpeakingPracticeScreenState extends State<SpeakingPracticeScreen> {
  late final SpeakingController _controller;
  final _apiClient = ApiClient();
  List<Lesson> _lessons = const [];
  Lesson? _selectedLesson;
  bool _loadingLessons = false;
  String? _lessonMessage;

  @override
  void initState() {
    super.initState();
    _controller = SpeakingController();
    _bootstrapLessons();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _selectedLesson?.title ??
        widget.lessonTitle ??
        _controller.state.selectedLessonName;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Speaking Practice'),
            if (title?.isNotEmpty == true)
              Text(
                title!,
                style: AppTextStyles.caption,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
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
              _lessonSelector(),
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

  Widget _lessonSelector() {
    final locked = widget.lessonId?.isNotEmpty == true;
    final title = _selectedLesson?.title ??
        widget.lessonTitle ??
        _controller.state.selectedLessonName;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lesson', style: AppTextStyles.caption),
          const SizedBox(height: 8),
          if (locked)
            Text(
              title?.isNotEmpty == true ? title! : 'Current lesson',
              style: AppTextStyles.h3,
              overflow: TextOverflow.ellipsis,
            )
          else if (_loadingLessons)
            const LinearProgressIndicator(minHeight: 4)
          else if (_lessons.isEmpty)
            Text(
              _lessonMessage ?? 'Select a lesson to start speaking practice.',
              style: AppTextStyles.body,
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _selectedLesson?.id,
              decoration: const InputDecoration(
                labelText: 'Select Lesson',
              ),
              items: [
                for (final lesson in _lessons)
                  DropdownMenuItem(
                    value: lesson.id,
                    child: Text(
                      lesson.title.isEmpty ? 'Untitled lesson' : lesson.title,
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
              child: Text(_lessonMessage!, style: AppTextStyles.caption),
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
          _emptyCard(state),
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
                      ? () => _controller.submitRecording(
                            state.selectedLessonId ?? _selectedLesson?.id ?? '',
                          )
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

  Widget _emptyCard(SpeakingState state) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Text(
          state.selectedLessonId == null
              ? 'Select a lesson to start speaking practice.'
              : 'No speaking exercises are available for this lesson yet.',
          style: AppTextStyles.body,
        ),
      );

  Future<void> _bootstrapLessons() async {
    final lockedLessonId = widget.lessonId;
    if (lockedLessonId != null && lockedLessonId.isNotEmpty) {
      await _controller.loadPrompts(
        lockedLessonId,
        lessonTitle: widget.lessonTitle,
      );
      return;
    }

    setState(() {
      _loadingLessons = true;
      _lessonMessage = null;
    });
    try {
      final response = await _apiClient.dio.get('/lessons');
      final lessons = LessonRepository.parseLessonListEnvelope(response.data);
      if (!mounted) return;
      setState(() {
        _lessons = lessons;
        _loadingLessons = false;
        _lessonMessage = lessons.isEmpty
            ? 'Select a lesson to start speaking practice.'
            : null;
      });
      if (lessons.length == 1) {
        _selectLesson(lessons.first);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingLessons = false;
        _lessonMessage =
            'Speaking practice is unavailable offline because this lesson has not been downloaded.';
      });
    }
  }

  Future<void> _selectLesson(Lesson lesson) async {
    setState(() {
      _selectedLesson = lesson;
      _lessonMessage = null;
    });
    await _controller.loadPrompts(lesson.id, lessonTitle: lesson.title);
  }
}
