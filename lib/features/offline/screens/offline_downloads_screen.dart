import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/content_state.dart';
import '../../../screens/flashcard_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../../lessons/state/lesson_controller.dart';
import '../repositories/offline_repository.dart';
import '../state/offline_controller.dart';

class OfflineDownloadsScreen extends ConsumerWidget {
  const OfflineDownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineState = ref.watch(offlineProvider);
    final lessonState = ref.watch(lessonProvider);
    final downloadedIds =
        offlineState.downloadedLessons.map((item) => item.lesson.id).toSet();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(lessonProvider.notifier).loadLessons();
            await ref.read(offlineProvider.notifier).loadDownloadedLessons();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              Row(
                children: [
                  const BackButton(),
                  Text('Offline Downloads', style: AppTextStyles.h2),
                ],
              ),
              const SizedBox(height: 16),
              if (offlineState.message != null)
                _Banner(
                  color: offlineState.status == ContentStatus.error
                      ? AppColors.sakura
                      : AppColors.matcha,
                  text: offlineState.message!,
                ),
              Text('DOWNLOADED', style: AppTextStyles.overline),
              const SizedBox(height: 8),
              if (offlineState.status == ContentStatus.loading &&
                  offlineState.downloadedLessons.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (offlineState.downloadedLessons.isEmpty)
                _EmptyPanel(
                  text: 'No downloaded lessons yet.',
                  icon: Icons.download_done_rounded,
                )
              else
                ...offlineState.downloadedLessons.map(
                  (item) => _DownloadedCard(
                    item: item,
                    removing: offlineState.activeLessonId == item.lesson.id &&
                        offlineState.status == ContentStatus.loading,
                    onReview: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            FlashcardScreen(lessonId: item.lesson.id),
                      ),
                    ),
                    onRemove: () => ref
                        .read(offlineProvider.notifier)
                        .removeDownloadedLesson(item.lesson.id),
                  ),
                ),
              const SizedBox(height: 20),
              Text('AVAILABLE', style: AppTextStyles.overline),
              const SizedBox(height: 8),
              if (lessonState.status == ContentStatus.loading &&
                  lessonState.lessons.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (lessonState.lessons.isEmpty)
                _EmptyPanel(
                  text: 'No lessons available to download.',
                  icon: Icons.cloud_off_rounded,
                  action: TextButton(
                    onPressed: () =>
                        ref.read(lessonProvider.notifier).loadLessons(),
                    child: const Text('Retry'),
                  ),
                )
              else
                ...lessonState.lessons
                    .where((lesson) => !downloadedIds.contains(lesson.id))
                    .map(
                      (lesson) => _AvailableCard(
                        title: lesson.title,
                        category: lesson.category,
                        description: lesson.description,
                        downloading: offlineState.activeLessonId == lesson.id &&
                            offlineState.status == ContentStatus.loading,
                        onDownload: lesson.isOfflineReady
                            ? () => ref
                                .read(offlineProvider.notifier)
                                .downloadLesson(lesson.id)
                            : null,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadedCard extends StatelessWidget {
  final DownloadedLesson item;
  final bool removing;
  final VoidCallback onReview;
  final VoidCallback onRemove;

  const _DownloadedCard({
    required this.item,
    required this.removing,
    required this.onReview,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          _IconBox(
            icon: Icons.download_done_rounded,
            fg: AppColors.matcha,
            bg: AppColors.matchaSoft,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.lesson.title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${_formatBytes(item.size)} · ${_formatDate(item.downloadedAt)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow_rounded,
                color: AppColors.primary, size: 20),
            onPressed: onReview,
          ),
          IconButton(
            icon: removing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline_rounded,
                    color: AppColors.sakura, size: 20),
            onPressed: removing ? null : onRemove,
          ),
        ],
      ),
    );
  }
}

class _AvailableCard extends StatelessWidget {
  final String title;
  final String category;
  final String description;
  final bool downloading;
  final VoidCallback? onDownload;

  const _AvailableCard({
    required this.title,
    required this.category,
    required this.description,
    required this.downloading,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          _IconBox(
            icon: Icons.menu_book_rounded,
            fg: AppColors.primary,
            bg: AppColors.primarySoft,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w700)),
                Text('$category · $description',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          IconButton(
            icon: downloading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.download_rounded,
                    color:
                        onDownload == null ? AppColors.mute : AppColors.primary,
                    size: 20,
                  ),
            onPressed: downloading ? null : onDownload,
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color fg;
  final Color bg;

  const _IconBox({
    required this.icon,
    required this.fg,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, color: fg, size: 18),
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final String text;

  const _Banner({
    required this.color,
    required this.text,
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
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final String text;
  final IconData icon;
  final Widget? action;

  const _EmptyPanel({
    required this.text,
    required this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.mute, size: 24),
          const SizedBox(height: 8),
          Text(text, style: AppTextStyles.caption),
          if (action != null) action!,
        ],
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return 'Unknown size';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _formatDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}
