import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../data/vocab_data.dart';

class QuizScreen extends StatefulWidget {
  final ValueChanged<int> onDone; // score
  const QuizScreen({super.key, required this.onDone});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _i = 0, _picked = -1, _time = 20, _score = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _time = 20;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_picked != -1) return;
      setState(() => _time = (_time - 1).clamp(0, 20));
      if (_time == 0) _choose(-1);
    });
  }

  void _choose(int n) {
    if (_picked != -1) return;
    setState(() => _picked = n);
    if (n == kQuestions[_i].correct) _score++;
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (_i < kQuestions.length - 1) {
        setState(() {
          _i++;
          _picked = -1;
        });
        _startTimer();
      } else {
        _timer?.cancel();
        widget.onDone(_score);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = kQuestions[_i];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Row(children: [
            const BackButton(),
            Expanded(
              child: Center(
                child: Text('Question ${_i + 1} / ${kQuestions.length}',
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.timer_outlined,
                    size: 14, color: AppColors.sakura),
                const SizedBox(width: 4),
                Text('${_time}s',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.ink)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (_i + 1) / kQuestions.length,
              minHeight: 8,
              backgroundColor: AppColors.line,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              boxShadow: AppShadows.elevated,
            ),
            child: Column(children: [
              Text('WHAT DOES THIS MEAN?',
                  style:
                      AppTextStyles.overline.copyWith(color: Colors.white70)),
              const SizedBox(height: 12),
              Text(q.kanji,
                  style: AppTextStyles.jp(70,
                      color: Colors.white, w: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(q.kana, style: AppTextStyles.jp(18, color: Colors.white70)),
            ]),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: q.options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, n) {
                final isPicked = _picked == n;
                final isCorrect = _picked != -1 && n == q.correct;
                final isWrong = isPicked && n != q.correct;
                final bg = isCorrect
                    ? AppColors.matchaSoft
                    : isWrong
                        ? AppColors.sakuraSoft
                        : Colors.white;
                final border = isCorrect
                    ? AppColors.matcha
                    : isWrong
                        ? AppColors.sakura
                        : AppColors.line;
                final badgeBg = isCorrect
                    ? AppColors.matcha
                    : isWrong
                        ? AppColors.sakura
                        : AppColors.inputBg;
                final badgeFg =
                    (isCorrect || isWrong) ? Colors.white : AppColors.mute;
                return GestureDetector(
                  onTap: () => _choose(n),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: border, width: 2),
                    ),
                    child: Row(children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(AppRadius.sm)),
                        alignment: Alignment.center,
                        child: Text(String.fromCharCode(65 + n),
                            style: TextStyle(
                                color: badgeFg,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(q.options[n],
                              style: AppTextStyles.body
                                  .copyWith(fontWeight: FontWeight.w600))),
                      if (isCorrect)
                        const Icon(Icons.check_rounded,
                            color: AppColors.matcha),
                      if (isWrong)
                        const Icon(Icons.close_rounded,
                            color: AppColors.sakura),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
