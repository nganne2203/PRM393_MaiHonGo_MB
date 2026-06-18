import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/localization/app_localizations.dart';
import '../core/state/content_state.dart';
import '../features/lessons/models/lesson.dart';
import '../features/lessons/state/lesson_controller.dart';
import '../features/offline/state/offline_controller.dart';
import '../shared/widgets/app_state_widgets.dart';
import '../theme/tokens.dart';
import '../theme/app_palette.dart';

class CategoriesScreen extends ConsumerWidget {
  final ValueChanged<Lesson> onPick;
  const CategoriesScreen({super.key, required this.onPick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lessonProvider);
    final isLoading = state.status == ContentStatus.loading;
    final isOffline = state.status == ContentStatus.offline;
    final hasError = state.status == ContentStatus.error;
    final offlineState = ref.watch(offlineProvider);
    final offlineController = ref.read(offlineProvider.notifier);
    final lessonController = ref.read(lessonProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('Lessons'), style: context.h1),
            const SizedBox(height: 4),
            Text(
              context.tr('Pick a category to start learning'),
              style: context.captionText,
            ),
            const SizedBox(height: 20),
            if (isOffline)
              AppStatusBanner.offline(
                message: context.tr('Showing cached lessons'),
              ),
            if (hasError && state.message != null)
              AppStatusBanner.error(
                message: state.message!,
                onRetry: () => ref.read(lessonProvider.notifier).loadLessons(),
              ),
            Expanded(
              child: isLoading && state.lessons.isEmpty
                  ? AppLoadingState(message: context.tr('Loading lessons...'))
                  : state.lessons.isEmpty
                      ? AppStatePlaceholder.empty(
                          icon: Icons.menu_book_outlined,
                          title: context.tr('No lessons available yet.'),
                        )
                      : RefreshIndicator(
                          onRefresh: () =>
                              ref.read(lessonProvider.notifier).loadLessons(),
                          child: GridView.builder(
                            padding: EdgeInsets.zero,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.95,
                            ),
                            itemCount: state.lessons.length,
                            itemBuilder: (_, i) => _CategoryCard(
                              item: state.lessons[i],
                              index: i,
                              downloading: offlineState.activeLessonId ==
                                      state.lessons[i].id &&
                                  offlineState.status == ContentStatus.loading,
                              onTap: () => onPick(state.lessons[i]),
                              onDownload: state.lessons[i].isOfflineReady &&
                                      !state.lessons[i].downloaded
                                  ? () async {
                                      await offlineController
                                          .downloadLesson(state.lessons[i].id);
                                      await lessonController.loadLessons();
                                    }
                                  : null,
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Lesson item;
  final int index;
  final bool downloading;
  final VoidCallback onTap;
  final Future<void> Function()? onDownload;
  const _CategoryCard({
    required this.item,
    required this.index,
    required this.downloading,
    required this.onTap,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _palettes[index % _palettes.length];
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: palette.colors,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  alignment: Alignment.center,
                  child: Icon(palette.icon, color: Colors.white, size: 24),
                ),
                const Spacer(),
                Text(item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                Text(item.category,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 10,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: item.downloaded ? 1 : 0,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                    item.downloaded
                        ? context.tr('Offline ready')
                        : context.l10n.isVietnamese
                            ? '${item.vocabIds.length} từ'
                            : '${item.vocabIds.length} words',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (!item.isOfflineReady)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.ink.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            ),
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.white.withValues(alpha: 0.25),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onDownload == null || downloading
                    ? null
                    : () async => onDownload!(),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: downloading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            item.downloaded
                                ? Icons.download_done_rounded
                                : item.isOfflineReady
                                    ? Icons.download_rounded
                                    : Icons.cloud_queue_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardPalette {
  final List<Color> colors;
  final IconData icon;

  const _CardPalette(this.colors, this.icon);
}

const _palettes = [
  _CardPalette([Color(0xFFFFB6C7), Color(0xFFFF8FB1)], Icons.school_rounded),
  _CardPalette([Color(0xFFA4DBA9), Color(0xFF7DCB8A)], Icons.eco_rounded),
  _CardPalette([Color(0xFF8A7BFF), Color(0xFF6C5CE7)], Icons.menu_book_rounded),
  _CardPalette([Color(0xFFFFD2A1), Color(0xFFFFA871)], Icons.work_rounded),
  _CardPalette([Color(0xFFB6DDF9), Color(0xFF7CC4F5)], Icons.translate_rounded),
];
