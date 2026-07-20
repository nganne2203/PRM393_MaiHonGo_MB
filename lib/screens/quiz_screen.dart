import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/app_localizations.dart';
import '../core/network/api_client.dart';
import '../features/progress/models/progress_models.dart';
import '../features/progress/repositories/progress_repository.dart';
import '../features/quiz/models/quiz_models.dart';
import '../features/quiz/repositories/quiz_repository.dart';
import '../features/vocabulary/models/vocabulary.dart';
import '../features/vocabulary/state/vocabulary_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class QuizResultArgs {
  final int score;
  final int total;
  final bool pendingSync;
  final String message;
  final String? lessonId;

  const QuizResultArgs({
    required this.score,
    required this.total,
    this.pendingSync = false,
    this.message = 'Quiz result saved.',
    this.lessonId,
  });
}

class QuizScreen extends ConsumerStatefulWidget {
  final String? lessonId;
  final ValueChanged<QuizResultArgs> onDone;

  const QuizScreen({
    super.key,
    this.lessonId,
    required this.onDone,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  final _quizRepository = QuizRepository();
  final _progressRepository = ProgressRepository();
  final _typingController = TextEditingController();
  final _answers = <QuizAnswer>[];
  final _startedAt = DateTime.now();

  List<QuizQuestion> _questions = const [];
  int _i = 0;
  int _picked = -1;
  int _time = 20;
  int _score = 0;
  bool _loading = true;
  bool _submitting = false;
  String? _message;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadQuestions);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _typingController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final repository = await ref.read(vocabularyRepositoryProvider.future);
      final result = widget.lessonId?.isNotEmpty == true
          ? await repository.getByLessonId(widget.lessonId!)
          : await repository.getVocabulary();
      final questions = _buildQuestions(result.data);
      setState(() {
        _questions = questions;
        _loading = false;
        _message =
            questions.isEmpty ? 'No quiz questions available yet.' : null;
      });
      if (questions.isNotEmpty) _startTimer();
    } catch (error) {
      setState(() {
        _loading = false;
        _message = ApiClient.describeError(error);
      });
    }
  }

  List<QuizQuestion> _buildQuestions(List<Vocabulary> vocabulary) {
    return QuizQuestionFactory.build(vocabulary);
  }

  void _startTimer() {
    _timer?.cancel();
    _time = 20;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_answered) return;
      setState(() => _time = (_time - 1).clamp(0, 20));
      if (_time == 0) _answer('');
    });
  }

  bool get _answered => _picked != -1;

  void _choose(int n) {
    if (_answered || _submitting) return;
    final question = _questions[_i];
    _answer(question.options[n], picked: n);
  }

  void _submitTyping() {
    if (_answered || _submitting) return;
    _answer(_typingController.text.trim());
  }

  void _answer(String selectedAnswer, {int picked = 0}) {
    if (_answered || _submitting) return;
    final question = _questions[_i];
    final isCorrect =
        _normalize(selectedAnswer) == _normalize(question.correctAnswer);
    setState(() {
      _picked = picked;
      if (isCorrect) _score += 1;
      _answers.add(
        QuizAnswer(
          questionId: question.id,
          type: question.type,
          selectedAnswer: selectedAnswer,
          correctAnswer: question.correctAnswer,
          isCorrect: isCorrect,
        ),
      );
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_i < _questions.length - 1) {
        setState(() {
          _i += 1;
          _picked = -1;
          _typingController.clear();
        });
        _startTimer();
      } else {
        _finish();
      }
    });
  }

  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');

  Future<void> _finish() async {
    _timer?.cancel();
    final completedMessage = context.tr('Quiz completed.');
    final pickLessonMessage =
        context.tr('Quiz completed. Pick a lesson to save progress.');
    final pendingMessage =
        context.tr('Quiz result saved locally. Pending sync.');
    final savedMessage = context.tr('Quiz result saved.');
    final isVietnamese = context.l10n.isVietnamese;
    setState(() => _submitting = true);
    final durationSec = DateTime.now().difference(_startedAt).inSeconds;
    final firstLessonId =
        _questions.isEmpty ? null : _questions.first.vocabulary.lessonId;
    final lessonId = widget.lessonId ?? firstLessonId;

    var pendingSync = false;
    var message = completedMessage;
    if (lessonId == null || lessonId.isEmpty) {
      message = pickLessonMessage;
    } else {
      final submission = QuizSubmission(
        lessonId: lessonId,
        score: _score,
        total: _questions.length,
        durationSec: durationSec,
        answers: _answers,
        syncSource: 'online',
        clientAttemptId: 'quiz-${DateTime.now().microsecondsSinceEpoch}',
      );
      try {
        final result = await _quizRepository.submitQuizResult(submission);
        pendingSync = result.pendingSync;
        message = pendingSync ? pendingMessage : savedMessage;
        await _progressRepository.updateProgress(
          ProgressUpdateRequest(
            lessonId: lessonId,
            lastViewedVocabIndex: _questions.length,
            completed: true,
            score: ((_score / _questions.length) * 100).round(),
            practiceType: 'quiz',
            totalPracticeScore: _score,
            clientUpdatedAt: DateTime.now(),
          ),
        );
      } catch (error) {
        final described = ApiClient.describeError(error);
        message = isVietnamese
            ? 'Đã hoàn thành quiz, nhưng lưu kết quả thất bại: $described'
            : 'Quiz completed, but result save failed: $described';
      }
    }

    if (!mounted) return;
    widget.onDone(
      QuizResultArgs(
        score: _score,
        total: _questions.length,
        pendingSync: pendingSync,
        message: message,
        lessonId: lessonId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar:
            AppBar(backgroundColor: Theme.of(context).scaffoldBackgroundColor),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              context.tr(_message ?? 'No quiz questions available yet.'),
              textAlign: TextAlign.center,
              style: context.bodyText,
            ),
          ),
        ),
      );
    }

    final q = _questions[_i];
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Row(children: [
              const BackButton(),
              Expanded(
                child: Center(
                  child: Text(
                      context.l10n.isVietnamese
                          ? 'Câu ${_i + 1} / ${_questions.length}'
                          : 'Question ${_i + 1} / ${_questions.length}',
                      style: context.bodyText
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
              ),
              _timerPill(),
            ]),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (_i + 1) / _questions.length,
                minHeight: 8,
                backgroundColor: context.colors.line,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(height: 24),
            _questionCard(q),
            const SizedBox(height: 20),
            Expanded(
              child: q.type == QuizQuestionType.typing
                  ? _typingAnswer(q)
                  : _multipleChoiceAnswers(q),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _timerPill() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.timer_outlined, size: 14, color: AppColors.sakura),
          const SizedBox(width: 4),
          Text('${_time}s',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: context.colors.ink)),
        ]),
      );

  Widget _questionCard(QuizQuestion q) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          boxShadow: AppShadows.elevated,
        ),
        child: Column(children: [
          Text(context.tr(q.prompt),
              style: AppTextStyles.overline.copyWith(color: Colors.white70)),
          const SizedBox(height: 12),
          Text(q.vocabulary.word,
              style: AppTextStyles.jp(70,
                  color: Colors.white, w: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(q.vocabulary.hiragana,
              style: AppTextStyles.jp(18, color: Colors.white70)),
        ]),
      );

  Widget _multipleChoiceAnswers(QuizQuestion q) => ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: q.options.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, n) {
          final selected = _picked != -1;
          final isPicked = _picked == n;
          final isCorrect = selected && q.options[n] == q.correctAnswer;
          final isWrong = isPicked && !isCorrect;
          final bg = isCorrect
              ? AppColors.matchaSoft
              : isWrong
                  ? AppColors.sakuraSoft
                  : context.colors.surface;
          final border = isCorrect
              ? AppColors.matcha
              : isWrong
                  ? AppColors.sakura
                  : context.colors.line;
          return GestureDetector(
            onTap: () => _choose(n),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: border, width: 2),
              ),
              child: Row(children: [
                Text(String.fromCharCode(65 + n),
                    style:
                        context.bodyText.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(context.tr(q.options[n]),
                        style: context.bodyText)),
                if (isCorrect)
                  const Icon(Icons.check_rounded, color: AppColors.matcha),
                if (isWrong)
                  const Icon(Icons.close_rounded, color: AppColors.sakura),
              ]),
            ),
          );
        },
      );

  Widget _typingAnswer(QuizQuestion q) {
    final answered = _answered;
    final selected = _answers.isEmpty ? '' : _answers.last.selectedAnswer;
    final isCorrect =
        answered && _normalize(selected) == _normalize(q.correctAnswer);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _typingController,
          enabled: !answered,
          decoration: InputDecoration(
            labelText: context.tr('Type the reading'),
            hintText: '例: みず',
          ),
          onSubmitted: (_) => _submitTyping(),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: answered ? null : _submitTyping,
          icon: const Icon(Icons.keyboard_return_rounded),
          label: Text(context.tr('Submit')),
        ),
        if (answered) ...[
          const SizedBox(height: 12),
          Text(
            isCorrect
                ? context.tr('Correct')
                : (context.l10n.isVietnamese
                    ? 'Đáp án đúng: ${q.correctAnswer}'
                    : 'Correct answer: ${q.correctAnswer}'),
            style: context.bodyText.copyWith(
              color: isCorrect ? AppColors.matcha : AppColors.sakura,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}
