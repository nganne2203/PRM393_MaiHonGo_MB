import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../core/network/api_client.dart';
import '../features/bookmarks/models/bookmark.dart';
import '../features/bookmarks/repositories/bookmark_repository.dart';
import '../features/vocabulary/models/vocabulary.dart';
import '../shared/widgets/app_state_widgets.dart';
import '../theme/app_theme.dart';
import '../theme/app_palette.dart';
import '../theme/tokens.dart';

class SavedScreen extends StatefulWidget {
  final ValueChanged<List<Vocabulary>> onReview;

  const SavedScreen({super.key, required this.onReview});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final _repository = BookmarkRepository();
  final _searchController = TextEditingController();
  List<Bookmark> _bookmarks = const [];
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final visible = query.isEmpty
        ? _bookmarks
        : _bookmarks.where((bookmark) {
            final vocab = bookmark.vocabulary;
            final haystack = [
              vocab?.word,
              vocab?.hiragana,
              vocab?.romaji,
              vocab?.meaningVi,
            ].whereType<String>().join(' ').toLowerCase();
            return haystack.contains(query);
          }).toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadBookmarks,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
          children: [
            Text(context.tr('Saved Words'), style: context.h1),
            const SizedBox(height: 4),
            Text(
              context.l10n.isVietnamese
                  ? '${_bookmarks.length} từ vựng đã lưu'
                  : '${_bookmarks.length} bookmarked vocabulary',
              style: context.captionText,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: context.tr('Search saved words...'),
                hintStyle: context.captionText,
                prefixIcon: Icon(Icons.search_rounded,
                    color: context.colors.mute, size: 18),
                filled: true,
                fillColor: context.colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide(color: context.colors.line),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _reviewSavedWords,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppGradients.sakura,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('Review Mode'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        Text(context.tr('Practice all your saved words'),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            if (_message != null)
              AppStatusBanner.error(
                message: _message!,
                onRetry: _loadBookmarks,
              ),
            if (_loading)
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: AppLoadingState(
                  message: context.tr('Loading saved words...'),
                ),
              )
            else if (visible.isEmpty)
              AppStatePlaceholder.empty(
                icon: Icons.bookmark_border_rounded,
                title: query.isEmpty
                    ? context.tr('Saved words will appear here.')
                    : context.tr('No saved words match your search.'),
              )
            else
              for (final bookmark in visible) ...[
                _bookmarkTile(bookmark),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }

  void _reviewSavedWords() {
    final cards = _bookmarks
        .map((bookmark) => bookmark.vocabulary)
        .whereType<Vocabulary>()
        .toList();
    if (cards.isEmpty) return;
    widget.onReview(cards);
  }

  Widget _bookmarkTile(Bookmark bookmark) {
    final vocab = bookmark.vocabulary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.sakuraSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              vocab?.word.isNotEmpty == true ? vocab!.word : '語',
              style: AppTextStyles.jp(24, color: AppColors.sakura),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vocab?.hiragana.isNotEmpty == true
                      ? vocab!.hiragana
                      : context.tr('Saved vocabulary'),
                  style: context.bodyText.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  [
                    if (vocab?.romaji.isNotEmpty == true) vocab!.romaji,
                    if (vocab?.meaningVi.isNotEmpty == true) vocab!.meaningVi,
                  ].join(' · '),
                  style: context.captionText,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: context.tr('Remove bookmark'),
            icon: const Icon(Icons.bookmark_rounded,
                color: AppColors.sakura, size: 20),
            onPressed: () => _removeBookmark(bookmark.vocabId),
          ),
        ],
      ),
    );
  }

  Future<void> _loadBookmarks() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final bookmarks = await _repository.getBookmarks();
      if (!mounted) return;
      setState(() {
        _bookmarks = bookmarks;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = ApiClient.describeError(error);
      });
    }
  }

  Future<void> _removeBookmark(String vocabId) async {
    if (vocabId.isEmpty) return;
    final previous = List<Bookmark>.from(_bookmarks);
    setState(() {
      _bookmarks =
          _bookmarks.where((bookmark) => bookmark.vocabId != vocabId).toList();
    });
    try {
      await _repository.removeBookmark(vocabId);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _bookmarks = previous;
        _message = ApiClient.describeError(error);
      });
    }
  }
}
