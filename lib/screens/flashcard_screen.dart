import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/state/content_state.dart';
import '../features/vocabulary/models/vocabulary.dart';
import '../features/vocabulary/state/vocabulary_controller.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/flashcard.dart';

class FlashcardScreen extends ConsumerStatefulWidget {
  final String? lessonId;
  const FlashcardScreen({
    super.key,
    this.lessonId,
  });

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen> {
  int _i = 0;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(vocabularyProvider.notifier)
          .loadVocabulary(lessonId: widget.lessonId),
    );
  }

  void _next(List<Vocabulary> cards) => setState(() {
        if (cards.isEmpty) return;
        _i = (_i + 1) % cards.length;
        _saved = false;
      });

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vocabularyProvider);
    final cards = state.vocabulary;
    final isLoading = state.status == ContentStatus.loading;
    final isOffline = state.status == ContentStatus.offline;
    final hasError = state.status == ContentStatus.error;
    if (_i >= cards.length && cards.isNotEmpty) _i = 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Row(children: [
              const BackButton(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: cards.isEmpty ? 0 : (_i + 1) / cards.length,
                        minHeight: 8,
                        backgroundColor: AppColors.line,
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                        cards.isEmpty ? '0 / 0' : '${_i + 1} / ${cards.length}',
                        style: const TextStyle(
                            color: AppColors.mute,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _saved = !_saved),
                icon: Icon(
                    _saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: _saved ? AppColors.sakura : AppColors.mute),
              ),
            ]),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: isLoading && cards.isEmpty
                    ? const CircularProgressIndicator()
                    : cards.isEmpty
                        ? _EmptyFlashcards(
                            isOffline: isOffline || hasError,
                            message: state.message,
                            onRetry: () =>
                                ref.read(vocabularyProvider.notifier).retry(),
                          )
                        : GestureDetector(
                            onHorizontalDragEnd: (d) {
                              if (d.primaryVelocity == null) return;
                              _next(cards);
                            },
                            child: FlipFlashcard(
                              key: ValueKey(cards[_i].id),
                              kanji: cards[_i].word,
                              kana: cards[_i].hiragana,
                              romaji: cards[_i].romaji,
                              meaning: cards[_i].meaningVi,
                              example: _example(cards[_i]).$1,
                              exampleTr: _example(cards[_i]).$2,
                            ),
                          ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ctrlBtn(Icons.close_rounded, AppColors.sakura,
                    AppColors.sakuraSoft, () => _next(cards)),
                const SizedBox(width: 16),
                _ctrlBtn(Icons.refresh_rounded, AppColors.primary,
                    AppColors.primarySoft, () {}),
                const SizedBox(width: 16),
                _ctrlBtn(Icons.check_rounded, Colors.white, AppColors.matcha,
                    () => _next(cards),
                    filled: true),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  Widget _ctrlBtn(IconData icon, Color color, Color bg, VoidCallback onTap,
      {bool filled = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: filled ? 64 : 56,
        height: filled ? 64 : 56,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: filled ? AppShadows.button : null,
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }

  (String, String) _example(Vocabulary vocabulary) {
    if (vocabulary.examples.isEmpty) return ('', '');
    final example = vocabulary.examples.first;
    return (example.jp, example.vi);
  }
}

class _EmptyFlashcards extends StatelessWidget {
  final bool isOffline;
  final String? message;
  final VoidCallback onRetry;

  const _EmptyFlashcards({
    required this.isOffline,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isOffline
              ? 'Lesson not available offline'
              : message ?? 'No flashcards found.',
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}
