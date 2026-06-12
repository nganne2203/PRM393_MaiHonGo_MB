import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/primary_button.dart';
import '../../lessons/models/lesson.dart';
import '../../lessons/state/lesson_controller.dart';
import '../../progress/models/progress_models.dart';
import '../../progress/repositories/progress_repository.dart';
import '../models/writing_models.dart';
import '../repositories/writing_repository.dart';
import 'writing_history_screen.dart';

class WritingPracticeArgs {
  final String? lessonId;
  final String? lessonTitle;

  const WritingPracticeArgs({
    this.lessonId,
    this.lessonTitle,
  });
}

class WritingPracticeScreen extends ConsumerStatefulWidget {
  final String? lessonId;
  final String? lessonTitle;

  const WritingPracticeScreen({
    super.key,
    this.lessonId,
    this.lessonTitle,
  });

  @override
  ConsumerState<WritingPracticeScreen> createState() =>
      _WritingPracticeScreenState();
}

class _WritingPracticeScreenState extends ConsumerState<WritingPracticeScreen> {
  final _repository = WritingRepository();
  final _progressRepository = ProgressRepository();
  final _answerController = TextEditingController();

  List<Lesson> _lessons = const [];
  List<WritingPrompt> _prompts = const [];
  WritingSubmission? _lastSubmission;
  String? _selectedLessonId;
  String? _selectedLessonTitle;
  int _index = 0;
  bool _loadingLessons = false;
  bool _loadingPrompts = false;
  bool _submitting = false;
  String? _message;
  bool get _lockedLesson => widget.lessonId?.isNotEmpty == true;

  WritingPrompt? get _currentPrompt {
    if (_prompts.isEmpty || _index >= _prompts.length) return null;
    return _prompts[_index];
  }

  @override
  void initState() {
    super.initState();
    _selectedLessonId = widget.lessonId;
    _selectedLessonTitle = widget.lessonTitle;
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (_lockedLesson) {
      await _loadPrompts();
      return;
    }
    await _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() {
      _loadingLessons = true;
      _message = null;
    });
    try {
      final repository = await ref.read(lessonRepositoryProvider.future);
      final result = await repository.getLessons();
      final lessons = result.data;
      setState(() {
        _lessons = lessons;
        if (lessons.length == 1) {
          _selectedLessonId = lessons.first.id;
          _selectedLessonTitle = lessons.first.title;
        }
      });
      if (_selectedLessonId?.isNotEmpty == true) {
        await _loadPrompts();
      }
    } catch (error) {
      setState(() => _message = ApiClient.describeError(error));
    } finally {
      if (mounted) setState(() => _loadingLessons = false);
    }
  }

  Future<void> _loadPrompts() async {
    final lessonId = _selectedLessonId;
    if (lessonId == null || lessonId.isEmpty) return;

    setState(() {
      _loadingPrompts = true;
      _message = null;
      _lastSubmission = null;
    });
    try {
      final prompts = await _repository.getPrompts(lessonId: lessonId);
      setState(() {
        _prompts = prompts;
        _index = 0;
        _answerController.clear();
      });
    } catch (error) {
      setState(() => _message = ApiClient.describeError(error));
    } finally {
      if (mounted) setState(() => _loadingPrompts = false);
    }
  }

  Future<void> _selectLesson(String? lessonId) async {
    if (lessonId == null || lessonId == _selectedLessonId) return;
    final lesson = _lessons.firstWhere((item) => item.id == lessonId);
    setState(() {
      _selectedLessonId = lesson.id;
      _selectedLessonTitle = lesson.title;
      _prompts = const [];
      _index = 0;
      _lastSubmission = null;
      _answerController.clear();
    });
    await _loadPrompts();
  }

  Future<void> _submit() async {
    final prompt = _currentPrompt;
    final lessonId = _selectedLessonId;
    final answer = _answerController.text.trim();
    if (prompt == null || lessonId == null || lessonId.isEmpty) return;
    if (answer.isEmpty) {
      setState(() => _message = 'Write an answer before submitting.');
      return;
    }

    setState(() {
      _submitting = true;
      _message = null;
    });

    final request = WritingSubmissionRequest(
      promptId: prompt.id,
      lessonId: lessonId,
      answerText: answer,
      submittedAt: DateTime.now(),
      syncSource: 'online',
      clientSubmissionId: 'writing-${DateTime.now().microsecondsSinceEpoch}',
    );

    try {
      final submission = await _repository.submit(request);
      if (!submission.pendingSync) {
        await _saveProgress(lessonId, submission.score);
      }
      setState(() {
        _lastSubmission = submission;
        _message = submission.pendingSync
            ? 'Saved offline. It will sync when you reconnect.'
            : 'Writing answer saved.';
      });
    } catch (error) {
      setState(() => _message = ApiClient.describeError(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _saveProgress(String lessonId, int score) async {
    try {
      await _progressRepository.updateProgress(
        ProgressUpdateRequest(
          lessonId: lessonId,
          lastViewedVocabIndex: _index,
          completed: _prompts.isNotEmpty && _index == _prompts.length - 1,
          score: score,
          practiceType: 'writing',
          completedWritingCount: 1,
          totalPracticeScore: score,
          clientUpdatedAt: DateTime.now(),
        ),
      );
    } catch (_) {
      // Writing has already been saved; progress can be retried later.
    }
  }

  void _nextPrompt() {
    if (_index >= _prompts.length - 1) return;
    setState(() {
      _index += 1;
      _lastSubmission = null;
      _message = null;
      _answerController.clear();
    });
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WritingHistoryScreen(
          lessonId: _selectedLessonId,
          lessonTitle: _selectedLessonTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _selectedLessonTitle?.isNotEmpty == true
        ? _selectedLessonTitle!
        : 'Select a lesson';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Writing Practice'),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(color: AppColors.mute),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'History',
            onPressed: _openHistory,
            icon: const Icon(Icons.history_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            if (!_lockedLesson) _lessonPicker(),
            if (_message != null) ...[
              const SizedBox(height: 12),
              _messageBanner(_message!),
            ],
            const SizedBox(height: 16),
            _body(),
          ],
        ),
      ),
    );
  }

  Widget _lessonPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLessonId,
          isExpanded: true,
          hint: Text(
            _loadingLessons ? 'Loading lessons...' : 'Select Lesson',
            style: AppTextStyles.body.copyWith(color: AppColors.mute),
          ),
          items: _lessons
              .map(
                (lesson) => DropdownMenuItem(
                  value: lesson.id,
                  child: Text(
                    lesson.title.isEmpty ? 'Untitled lesson' : lesson.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: _loadingLessons ? null : _selectLesson,
        ),
      ),
    );
  }

  Widget _body() {
    if (_loadingPrompts || _loadingLessons) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_selectedLessonId == null || _selectedLessonId!.isEmpty) {
      return _emptyState(
        Icons.edit_note_rounded,
        'Select a lesson to start writing practice.',
      );
    }

    if (_prompts.isEmpty) {
      return _emptyState(
        Icons.inbox_rounded,
        'No writing exercises are available for this lesson yet.',
      );
    }

    final prompt = _currentPrompt!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${_index + 1} / ${_prompts.length}',
          style: AppTextStyles.overline,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (_index + 1) / _prompts.length,
          minHeight: 8,
          backgroundColor: AppColors.line,
          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          borderRadius: BorderRadius.circular(999),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_promptTypeLabel(prompt.promptType),
                  style: AppTextStyles.overline),
              const SizedBox(height: 10),
              Text(
                prompt.promptText,
                style: AppTextStyles.h2.copyWith(fontSize: 22),
              ),
              if (prompt.rubric.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(prompt.rubric, style: AppTextStyles.caption),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _answerController,
          maxLines: 7,
          minLines: 5,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: 'Write your answer',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_lastSubmission != null) _feedbackCard(_lastSubmission!, prompt),
        const SizedBox(height: 16),
        PrimaryButton(
          label: _submitting ? 'Saving...' : 'Submit Answer',
          trailingIcon: Icons.check_rounded,
          onTap: _submitting ? () {} : _submit,
        ),
        if (_index < _prompts.length - 1) ...[
          const SizedBox(height: 12),
          GhostButton(label: 'Next prompt', onTap: _nextPrompt),
        ],
      ],
    );
  }

  Widget _feedbackCard(WritingSubmission submission, WritingPrompt prompt) {
    final sample = prompt.sampleAnswer.isNotEmpty
        ? prompt.sampleAnswer
        : prompt.expectedAnswer;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            submission.pendingSync ? 'Pending sync' : 'Feedback',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            submission.feedback.isEmpty
                ? 'Your answer has been submitted for review.'
                : submission.feedback,
            style: AppTextStyles.caption.copyWith(color: AppColors.ink),
          ),
          if (sample.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Sample answer', style: AppTextStyles.overline),
            const SizedBox(height: 4),
            Text(sample, style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 40),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _messageBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(message, style: AppTextStyles.caption),
    );
  }

  String _promptTypeLabel(String type) {
    return switch (type) {
      'translation' => 'TRANSLATION',
      'vocabulary' => 'VOCABULARY',
      'free_text' => 'FREE WRITING',
      _ => 'SENTENCE',
    };
  }
}
