import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/media/audio_cache_service.dart';
import '../core/media/audio_player_service.dart';
import '../core/network/api_client.dart';
import '../core/state/content_state.dart';
import '../features/bookmarks/repositories/bookmark_repository.dart';
import '../features/lessons/models/lesson.dart';
import '../features/vocabulary/models/vocabulary.dart';
import '../features/vocabulary/state/vocabulary_controller.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

class VocabScreen extends ConsumerStatefulWidget {
  final VoidCallback onStart;
  final Lesson? lesson;
  const VocabScreen({
    super.key,
    required this.onStart,
    this.lesson,
  });

  @override
  ConsumerState<VocabScreen> createState() => _VocabScreenState();
}

class _VocabScreenState extends ConsumerState<VocabScreen> {
  String _filter = 'All';
  final Set<String> _saved = {};
  final _searchController = TextEditingController();
  final _audioPlayerService = AudioPlayerService();
  final _audioCacheService = AudioCacheService();
  final _bookmarkRepository = BookmarkRepository();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () async {
        await ref
            .read(vocabularyProvider.notifier)
            .loadVocabulary(lessonId: widget.lesson?.id);
        await _loadBookmarks();
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _audioPlayerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vocabularyProvider);
    final list = state.vocabulary;
    final tags = _tagsFor(list);
    final isLoading = state.status == ContentStatus.loading;
    final isOffline = state.status == ContentStatus.offline;
    final hasError = state.status == ContentStatus.error;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const BackButton(),
            Expanded(
              child: Text(
                widget.lesson?.title ?? 'Vocabulary',
                style: AppTextStyles.h2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) => ref
                    .read(vocabularyProvider.notifier)
                    .searchVocabulary(value),
                decoration: InputDecoration(
                  hintText: 'Search words...',
                  hintStyle: AppTextStyles.caption,
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.mute, size: 18),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.lg)),
              child:
                  const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
            ),
          ]),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tags.map((f) {
                final on = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _filter = f);
                      ref.read(vocabularyProvider.notifier).filterByTag(f);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: on ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: on ? AppColors.primary : AppColors.line),
                      ),
                      child: Text(f,
                          style: TextStyle(
                            color: on ? Colors.white : AppColors.mute,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          )),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          if (isOffline)
            _StatusBanner(
              icon: Icons.cloud_off_rounded,
              text: 'Showing cached vocabulary',
              color: AppColors.gold,
            ),
          if (hasError && state.message != null)
            _StatusBanner(
              icon: Icons.error_outline_rounded,
              text: state.message!,
              color: AppColors.sakura,
              onRetry: () => ref.read(vocabularyProvider.notifier).retry(),
            ),
          Expanded(
            child: isLoading && list.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? _EmptyVocabulary(
                        isOffline: hasError || isOffline,
                        onRetry: () =>
                            ref.read(vocabularyProvider.notifier).retry(),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(vocabularyProvider.notifier).retry(),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: list.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, idx) {
                            final v = list[idx];
                            final saved = _saved.contains(v.id);
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.lg),
                                boxShadow: AppShadows.card,
                              ),
                              child: Row(children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                      color: AppColors.primarySoft,
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md)),
                                  alignment: Alignment.center,
                                  child: Text(v.word,
                                      style: AppTextStyles.jp(24,
                                          color: AppColors.primary)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Text(v.hiragana,
                                          style: AppTextStyles.body.copyWith(
                                              fontWeight: FontWeight.w700)),
                                      const SizedBox(width: 6),
                                      if (v.tags.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: v.tags.first == 'N5'
                                                ? AppColors.sakuraSoft
                                                : AppColors.skySoft,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(v.tags.first,
                                              style: TextStyle(
                                                color: v.tags.first == 'N5'
                                                    ? AppColors.sakura
                                                    : AppColors.sky,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                              )),
                                        ),
                                    ]),
                                    Text('${v.romaji} · ${v.meaningVi}',
                                        style: AppTextStyles.caption),
                                  ],
                                )),
                                IconButton(
                                  icon: const Icon(Icons.volume_up_rounded,
                                      color: AppColors.primary, size: 18),
                                  onPressed: () => _playAudio(v.audioUrl),
                                ),
                                IconButton(
                                  icon: Icon(
                                      saved
                                          ? Icons.bookmark_rounded
                                          : Icons.bookmark_border_rounded,
                                      color: saved
                                          ? AppColors.sakura
                                          : AppColors.mute,
                                      size: 18),
                                  onPressed: () => _toggleBookmark(v.id),
                                ),
                              ]),
                            );
                          },
                        ),
                      ),
          ),
          const SizedBox(height: 8),
          PrimaryButton(
              label: 'Start Flashcard Session →',
              onTap: list.isEmpty ? () {} : widget.onStart),
        ]),
      ),
    );
  }

  List<String> _tagsFor(List<Vocabulary> vocabulary) {
    final tags = vocabulary.expand((item) => item.tags).toSet().toList()
      ..sort();
    return ['All', ...tags];
  }

  Future<void> _playAudio(String audioUrl) async {
    final url = audioUrl.trim();
    if (url.isEmpty) {
      _showAudioMessage('Audio is not available yet.');
      return;
    }

    try {
      final cachedPath = await _audioCacheService.cachedPathForUrl(url);
      if (cachedPath != null) {
        await _audioPlayerService.playLocalFile(cachedPath);
        return;
      }
      await _audioPlayerService.playUrl(url);
      await _audioCacheService.cacheRemoteAudio(url);
    } catch (error) {
      _showAudioMessage(ApiClient.describeError(error));
    }
  }

  void _showAudioMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _loadBookmarks() async {
    try {
      final ids = await _bookmarkRepository.getBookmarkedVocabIds();
      if (!mounted) return;
      setState(() {
        _saved
          ..clear()
          ..addAll(ids);
      });
    } catch (_) {
      // Keep vocabulary usable even when bookmarks cannot be loaded.
    }
  }

  Future<void> _toggleBookmark(String vocabId) async {
    if (vocabId.isEmpty) {
      _showAudioMessage('Cannot bookmark this vocabulary item yet.');
      return;
    }

    final wasSaved = _saved.contains(vocabId);
    setState(() {
      if (wasSaved) {
        _saved.remove(vocabId);
      } else {
        _saved.add(vocabId);
      }
    });

    try {
      if (wasSaved) {
        await _bookmarkRepository.removeBookmark(vocabId);
      } else {
        await _bookmarkRepository.addBookmark(vocabId);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (wasSaved) {
          _saved.add(vocabId);
        } else {
          _saved.remove(vocabId);
        }
      });
      _showAudioMessage(ApiClient.describeError(error));
    }
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback? onRetry;

  const _StatusBanner({
    required this.icon,
    required this.text,
    required this.color,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Retry')),
      ]),
    );
  }
}

class _EmptyVocabulary extends StatelessWidget {
  final bool isOffline;
  final VoidCallback onRetry;

  const _EmptyVocabulary({
    required this.isOffline,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isOffline ? 'Lesson not available offline' : 'No vocabulary found.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
