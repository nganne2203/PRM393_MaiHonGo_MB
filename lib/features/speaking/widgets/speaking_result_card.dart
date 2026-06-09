import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../models/speaking_models.dart';

class SpeakingResultCard extends StatelessWidget {
  final SpeakingAttempt attempt;
  final VoidCallback onRetry;

  const SpeakingResultCard({
    super.key,
    required this.attempt,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = attempt.status == 'pendingSync';
    final isFailed = attempt.status == 'failed';
    final scoreColor = isFailed
        ? AppColors.sakura
        : isPending
            ? AppColors.gold
            : AppColors.matcha;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: scoreColor.withValues(alpha: 0.16),
                child: Icon(Icons.graphic_eq_rounded, color: scoreColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isPending ? 'Queued for AI review' : 'AI Review',
                  style: AppTextStyles.h3,
                ),
              ),
              Text(
                '${attempt.similarityScore}',
                style: TextStyle(
                  color: scoreColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Line(label: 'Expected', value: attempt.expectedText),
          _Line(
              label: 'Transcript',
              value: attempt.transcript.isEmpty ? '-' : attempt.transcript),
          const SizedBox(height: 12),
          Text(attempt.feedback, style: AppTextStyles.body),
          if (attempt.correctWords.isNotEmpty ||
              attempt.wrongWords.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...attempt.correctWords.map(
                  (word) => _Chip(label: word, color: AppColors.matcha),
                ),
                ...attempt.wrongWords.map(
                  (word) => _Chip(label: word, color: AppColors.sakura),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;

  const _Line({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}
