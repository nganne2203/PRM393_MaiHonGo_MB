import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';

class FlipFlashcard extends StatefulWidget {
  final String kanji;
  final String kana;
  final String romaji;
  final String meaning;
  final String example;
  final String exampleTr;
  const FlipFlashcard({
    super.key,
    required this.kanji,
    required this.kana,
    required this.romaji,
    required this.meaning,
    required this.example,
    required this.exampleTr,
  });

  @override
  State<FlipFlashcard> createState() => _FlipFlashcardState();
}

class _FlipFlashcardState extends State<FlipFlashcard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _flip() => _c.isCompleted ? _c.reverse() : _c.forward();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final angle = _c.value * math.pi;
          final showBack = _c.value > 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _back(),
                  )
                : _front(),
          );
        },
      ),
    );
  }

  Widget _front() => Container(
        height: 420,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          boxShadow: AppShadows.elevated,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('TAP TO FLIP',
                style: AppTextStyles.overline.copyWith(color: Colors.white70)),
            const SizedBox(height: 16),
            Text(widget.kanji,
                style: AppTextStyles.jp(110,
                    color: Colors.white, w: FontWeight.w900)),
            const SizedBox(height: 12),
            Text(widget.kana,
                style: AppTextStyles.jp(22,
                    color: Colors.white70, w: FontWeight.w500)),
            const SizedBox(height: 32),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(Icons.volume_up_rounded,
                  color: Colors.white, size: 20),
            ),
          ],
        ),
      );

  Widget _back() => Container(
        height: 420,
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          boxShadow: AppShadows.elevated,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('MEANING', style: AppTextStyles.overline),
            const SizedBox(height: 12),
            Text(widget.meaning,
                style: AppTextStyles.h1.copyWith(fontSize: 30)),
            const SizedBox(height: 4),
            Text(widget.romaji, style: AppTextStyles.caption),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.example,
                      style: AppTextStyles.jp(16, w: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(widget.exampleTr, style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      );
}
