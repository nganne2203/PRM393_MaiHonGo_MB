import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import '../features/bookmarks/models/bookmark.dart';
import '../features/bookmarks/repositories/bookmark_repository.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class SavedScreen extends StatefulWidget {
  final VoidCallback onReview;

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
            Text('Saved Words', style: AppTextStyles.h1),
            const SizedBox(height: 4),
            Text('${_bookmarks.length} bookmarked vocabulary',
                style: AppTextStyles.caption),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search saved words...',
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
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _bookmarks.isEmpty ? null : widget.onReview,
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Review Mode',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        Text('Practice all your saved words',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            if (_message != null) _messageCard(),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (visible.isEmpty)
              _emptyCard()
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

  Widget _bookmarkTile(Bookmark bookmark) {
    final vocab = bookmark.vocabulary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
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
                      : 'Saved vocabulary',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  [
                    if (vocab?.romaji.isNotEmpty == true) vocab!.romaji,
                    if (vocab?.meaningVi.isNotEmpty == true) vocab!.meaningVi,
                  ].join(' · '),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove bookmark',
            icon: const Icon(Icons.bookmark_rounded,
                color: AppColors.sakura, size: 20),
            onPressed: () => _removeBookmark(bookmark.vocabId),
          ),
        ],
      ),
    );
  }

  Widget _messageCard() => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.sakuraSoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          _message!,
          style: const TextStyle(
            color: AppColors.sakura,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _emptyCard() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            const Icon(Icons.bookmark_border_rounded,
                color: AppColors.mute, size: 24),
            const SizedBox(height: 8),
            Text('Saved words will appear here.', style: AppTextStyles.caption),
          ],
        ),
      );

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
