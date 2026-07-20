import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/localization/app_localizations.dart';
import '../core/network/api_client.dart';
import '../core/state/content_state.dart';
import '../features/bookmarks/repositories/bookmark_repository.dart';
import '../features/flashcards/models/flashcard_session.dart';
import '../features/flashcards/repositories/flashcard_session_repository.dart';
import '../features/flashcards/screens/flashcard_summary_screen.dart';
import '../features/vocabulary/models/vocabulary.dart';
import '../features/vocabulary/state/vocabulary_controller.dart';
import '../shared/widgets/app_state_widgets.dart';
import '../theme/app_palette.dart';
import '../theme/tokens.dart';
import '../widgets/flashcard.dart';

class FlashcardScreen extends ConsumerStatefulWidget {
  final String? lessonId;
  final List<Vocabulary>? initialCards;
  const FlashcardScreen({
    super.key,
    this.lessonId,
    this.initialCards,
  });

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen> {
  final Set<String> _savedIds = {};
  final _bookmarkRepository = BookmarkRepository();
  FlashcardSessionState? _session;
  int _resetToken = 0;
  bool _finishing = false;
  bool _resumeAttempted = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () async {
        if (widget.initialCards == null) {
          await ref
              .read(vocabularyProvider.notifier)
              .loadVocabulary(lessonId: widget.lessonId);
        }
        final cards =
            widget.initialCards ?? ref.read(vocabularyProvider).vocabulary;
        await _restoreResume(cards);
        await _loadBookmarks();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vocabularyProvider);
    final cards = widget.initialCards ?? state.vocabulary;
    _syncSession(cards);
    final session = _session;
    final isLoading = state.status == ContentStatus.loading;
    final isOffline = state.status == ContentStatus.offline;
    final hasError = state.status == ContentStatus.error;
    final currentCard = session?.currentCard;
    final isSaved =
        currentCard == null ? false : _savedIds.contains(currentCard.id);
    final answeredCards = session?.answeredCards ?? 0;
    final totalCards = session?.totalCards ?? cards.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                        value: totalCards == 0 ? 0 : answeredCards / totalCards,
                        minHeight: 8,
                        backgroundColor: context.colors.line,
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                        totalCards == 0
                            ? '0 / 0'
                            : '$answeredCards / $totalCards',
                        style: TextStyle(
                            color: context.colors.mute,
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
                    color: isSaved ? AppColors.sakura : context.colors.mute),
              ),
            ]),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: isLoading && cards.isEmpty && widget.initialCards == null
                    ? AppLoadingState(
                        message: context.tr('Loading flashcards...'))
                    : cards.isEmpty
                        ? (isOffline || hasError
                            ? AppStatePlaceholder.offline(
                                title:
                                    context.tr('Lesson not available offline'),
                                message: state.message,
                                onRetry: () => ref
                                    .read(vocabularyProvider.notifier)
                                    .retry(),
                              )
                            : AppStatePlaceholder.empty(
                                icon: Icons.style_outlined,
                                title: context.tr('No flashcards found.'),
                                onRetry: () => ref
                                    .read(vocabularyProvider.notifier)
                                    .retry(),
                              ))
                        : GestureDetector(
                            onHorizontalDragEnd: (details) {
                              final velocity = details.primaryVelocity ?? 0;
                              if (velocity.abs() < 250) return;
                              _answerCurrent(
                                velocity > 0
                                    ? FlashcardAnswerStatus.notLearned
                                    : FlashcardAnswerStatus.learned,
                              );
                            },
                            child: FlipFlashcard(
                              key: ValueKey(currentCard?.id),
                              kanji: currentCard?.word ?? '',
                              kana: currentCard?.hiragana ?? '',
                              romaji: currentCard?.romaji ?? '',
                              meaning: currentCard?.meaningVi ?? '',
                              example: currentCard == null
                                  ? ''
                                  : _example(currentCard).$1,
                              exampleTr: currentCard == null
                                  ? ''
                                  : _example(currentCard).$2,
                              audioUrl: currentCard?.audioUrl ?? '',
                              resetToken: _resetToken,
                            ),
                          ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ctrlBtn(
                    Icons.close_rounded,
                    AppColors.sakura,
                    AppColors.sakuraSoft,
                    () => _answerCurrent(FlashcardAnswerStatus.notLearned)),
                const SizedBox(width: 16),
                _ctrlBtn(Icons.refresh_rounded, AppColors.primary,
                    AppColors.primarySoft, _retryCurrent),
                const SizedBox(width: 16),
                _ctrlBtn(Icons.check_rounded, Colors.white, AppColors.matcha,
                    () => _answerCurrent(FlashcardAnswerStatus.learned),
                    filled: true),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  void _syncSession(List<Vocabulary> cards) {
    final session = _session;
    if (session != null && _sameCards(session.cards, cards)) return;
    _session = FlashcardSessionState.start(cards);
  }

  bool _sameCards(List<Vocabulary> a, List<Vocabulary> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i += 1) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
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

  Future<void> _answerCurrent(FlashcardAnswerStatus status) async {
    final session = _session;
    if (session == null || session.isEmpty || _finishing) return;

    final answered = session.answerCurrent(status);
    setState(() => _session = answered);

    if (answered.isLastCard) {
      await _finishSession(answered);
      return;
    }

    setState(() {
      _session = answered.moveNext();
      _resetToken += 1;
    });
    await _saveResume();
  }

  void _retryCurrent() {
    if (_session?.isEmpty ?? true) return;
    setState(() => _resetToken += 1);
  }

  Future<void> _finishSession(FlashcardSessionState session) async {
    setState(() => _finishing = true);
    final result = session.result(lessonId: widget.lessonId);

    try {
      final repository =
          await ref.read(flashcardSessionRepositoryProvider.future);
      await repository.saveResult(result);
    } catch (error) {
      _showMessage(ApiClient.describeError(error));
    }
    try {
      final repository =
          await ref.read(flashcardSessionRepositoryProvider.future);
      await repository.clearResume(_sessionKey(session.cards));
    } catch (_) {}

    if (!mounted) return;
    setState(() => _finishing = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardSummaryScreen(
          result: result,
          originalCards: session.originalCards,
        ),
      ),
    );
  }

  Future<void> _restoreResume(List<Vocabulary> cards) async {
    if (_resumeAttempted || cards.isEmpty) return;
    _resumeAttempted = true;
    try {
      final repository =
          await ref.read(flashcardSessionRepositoryProvider.future);
      final resumed = await repository.loadResume(_sessionKey(cards), cards);
      if (!mounted || resumed == null) return;
      setState(() => _session = resumed);
    } catch (_) {
      // A missing resume record must not block the flashcard session.
    }
  }

  Future<void> _saveResume() async {
    final session = _session;
    if (session == null || session.cards.isEmpty) return;
    try {
      final repository =
          await ref.read(flashcardSessionRepositoryProvider.future);
      await repository.saveResume(_sessionKey(session.cards), session);
    } catch (_) {
      // Resume persistence is best effort; the active session stays usable.
    }
  }

  String _sessionKey(List<Vocabulary> cards) {
    final lessonId = widget.lessonId;
    if (lessonId != null && lessonId.isNotEmpty) return 'lesson:$lessonId';
    final ids = cards
        .map((item) => item.id)
        .where((id) => id.isNotEmpty)
        .toList()
      ..sort();
    return 'cards:${ids.join(',')}';
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
      _showMessage(context.tr('Cannot bookmark this vocabulary item yet.'));
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
        await _bookmarkRepository.addBookmark(
          vocabulary.id,
          vocabulary: vocabulary,
        );
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
