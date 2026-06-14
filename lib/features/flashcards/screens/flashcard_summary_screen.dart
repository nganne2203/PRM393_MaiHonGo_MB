import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../screens/flashcard_screen.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../../vocabulary/models/vocabulary.dart';
import '../models/flashcard_session.dart';

class FlashcardSummaryScreen extends StatelessWidget {
  final FlashcardSessionResult result;
  final List<Vocabulary> originalCards;

  const FlashcardSummaryScreen({
    super.key,
    required this.result,
    required this.originalCards,
  });

  @override
  Widget build(BuildContext context) {
    final hasReviewCards = result.notLearnedCards.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.tr('Session Complete')),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            _scoreCard(context),
            const SizedBox(height: 16),
            _wordSection(
              context: context,
              title: 'Learned',
              color: AppColors.matcha,
              words: result.learnedCards,
            ),
            const SizedBox(height: 12),
            _wordSection(
              context: context,
              title: 'Need Review',
              color: AppColors.sakura,
              words: result.notLearnedCards,
            ),
            const SizedBox(height: 20),
            if (hasReviewCards)
              FilledButton.icon(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FlashcardScreen(
                      lessonId: result.lessonId,
                      initialCards: result.notLearnedCards,
                    ),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.tr('Review Not Learned')),
              )
            else
              _messageCard(
                  context, context.tr('Great job! No words need review.')),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => FlashcardScreen(
                    lessonId: result.lessonId,
                    initialCards: originalCards,
                  ),
                ),
              ),
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(context.tr('Restart All')),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              icon: const Icon(Icons.home_rounded),
              label: Text(context.tr('Back to Home')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreCard(BuildContext context) {
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
            context.tr('Session Complete'),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _stat(context, 'Total', '${result.totalCards}'),
              _stat(context, 'Learned', '${result.learnedCount}'),
              _stat(context, 'Need Review', '${result.notLearnedCount}'),
              _stat(context, 'Accuracy', '${result.accuracy}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(label),
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );

  Widget _wordSection({
    required BuildContext context,
    required String title,
    required Color color,
    required List<Vocabulary> words,
  }) {
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
          Text(
            '${context.tr(title)} (${words.length})',
            style: AppTextStyles.h3.copyWith(color: color),
          ),
          const SizedBox(height: 10),
          if (words.isEmpty)
            Text(context.tr('No words in this group.'),
                style: context.captionText)
          else
            for (final word in words) ...[
              Row(
                children: [
                  Text(word.word, style: AppTextStyles.jp(20, color: color)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${word.hiragana} · ${word.meaningVi}',
                      style: context.captionText,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _messageCard(BuildContext context, String message) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.matchaSoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          message,
          style: AppTextStyles.body.copyWith(
            color: AppColors.matcha,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}
