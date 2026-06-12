import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../core/state/content_state.dart';
import '../features/bookmarks/repositories/bookmark_repository.dart';
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
  final Set<String> _savedIds = {};
  final _bookmarkRepository = BookmarkRepository();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () async {
        await ref
            .read(vocabularyProvider.notifier)
            .loadVocabulary(lessonId: widget.lessonId);
        await _loadBookmarks();
      },
    );
  }

  void _next(List<Vocabulary> cards) => setState(() {
        if (cards.isEmpty) return;
        _i = (_i + 1) % cards.length;
      });

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vocabularyProvider);
    final cards = state.vocabulary;
    final isLoading = state.status == ContentStatus.loading;
    final isOffline = state.status == ContentStatus.offline;
    final hasError = state.status == ContentStatus.error;
    if (_i >= cards.length && cards.isNotEmpty) _i = 0;
    final currentCard = cards.isEmpty ? null : cards[_i];
    final isSaved =
        currentCard == null ? false : _savedIds.contains(currentCard.id);

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
                onPressed: currentCard == null
                    ? null
                    : () => _toggleBookmark(currentCard),
                icon: Icon(
                    isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: isSaved ? AppColors.sakura : AppColors.mute),
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
                              audioUrl: cards[_i].audioUrl,
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

  Future<void> _loadBookmarks() async {
    try {
      final ids = await _bookmarkRepository.getBookmarkedVocabIds();
      if (!mounted) return;
      setState(() {
        _savedIds
          ..clear()
          ..addAll(ids);
      });
    } catch (_) {
      // Flashcards should remain usable if saved state cannot be fetched.
    }
  }

  Future<void> _toggleBookmark(Vocabulary vocabulary) async {
    if (vocabulary.id.isEmpty) {
      _showMessage('Cannot bookmark this vocabulary item yet.');
      return;
    }

    final wasSaved = _savedIds.contains(vocabulary.id);
    setState(() {
      if (wasSaved) {
        _savedIds.remove(vocabulary.id);
      } else {
        _savedIds.add(vocabulary.id);
      }
    });

    try {
      if (wasSaved) {
        await _bookmarkRepository.removeBookmark(vocabulary.id);
      } else {
        await _bookmarkRepository.addBookmark(vocabulary.id);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (wasSaved) {
          _savedIds.add(vocabulary.id);
        } else {
          _savedIds.remove(vocabulary.id);
        }
      });
      _showMessage(ApiClient.describeError(error));
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
