import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

class ResultScreen extends StatefulWidget {
  final int score, total;
  final VoidCallback onRetry;
  final VoidCallback onContinue;
  const ResultScreen({super.key, required this.score, required this.total,
      required this.onRetry, required this.onContinue});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final _ctrl = ConfettiController(duration: const Duration(seconds: 2))..play();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final accuracy = ((widget.score / widget.total) * 100).round();
    return Stack(children: [
      ListView(padding: EdgeInsets.zero, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
          decoration: const BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              Container(
                width: 96, height: 96,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Text('🏆', style: TextStyle(fontSize: 50)),
              ),
              const SizedBox(height: 20),
              Text('Excellent!', style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 26)),
              const SizedBox(height: 4),
              Text("You've completed the quiz",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
            ]),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadows.elevated,
              ),
              child: Column(children: [
                Text('YOUR SCORE', style: AppTextStyles.overline),
                const SizedBox(height: 8),
                ShaderMask(
                  shaderCallback: (r) => AppGradients.primary.createShader(r),
                  child: Text('${widget.score} / ${widget.total}',
                      style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  _stat('🎯', '$accuracy%', 'Accuracy', AppColors.sakuraSoft),
                  const SizedBox(width: 8),
                  _stat('⚡', '+${widget.score * 15}', 'XP earned', AppColors.primarySoft),
                  const SizedBox(width: 8),
                  _stat('🏅', '3', 'Badges', AppColors.matchaSoft),
                ]),
              ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Row(children: [
            Expanded(child: GhostButton(label: '↻ Retry', onTap: widget.onRetry)),
            const SizedBox(width: 12),
            Expanded(child: PrimaryButton(label: 'Continue', trailingIcon: Icons.arrow_forward_rounded, onTap: widget.onContinue)),
          ]),
        ),
      ]),
      Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _ctrl,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 25,
          colors: const [AppColors.sakura, AppColors.gold, AppColors.primary, AppColors.matcha],
        ),
      ),
    ]);
  }

  Widget _stat(String emoji, String value, String label, Color bg) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        Text(label, style: const TextStyle(color: AppColors.mute, fontSize: 10)),
      ]),
    ),
  );
}
