import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/state/content_state.dart';
import '../features/lessons/models/lesson.dart';
import '../features/lessons/state/lesson_controller.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';

class CategoriesScreen extends ConsumerWidget {
  final ValueChanged<Lesson> onPick;
  const CategoriesScreen({super.key, required this.onPick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lessonProvider);
    final isLoading = state.status == ContentStatus.loading;
    final isOffline = state.status == ContentStatus.offline;
    final hasError = state.status == ContentStatus.error;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lessons', style: AppTextStyles.h1),
            const SizedBox(height: 4),
            Text('Pick a category to start learning',
                style: AppTextStyles.caption),
            const SizedBox(height: 20),
            if (isOffline)
              _StatusBanner(
                icon: Icons.cloud_off_rounded,
                text: 'Showing cached lessons',
                color: AppColors.gold,
              ),
            if (hasError && state.message != null)
              _StatusBanner(
                icon: Icons.error_outline_rounded,
                text: state.message!,
                color: AppColors.sakura,
                onRetry: () => ref.read(lessonProvider.notifier).loadLessons(),
              ),
            Expanded(
              child: isLoading && state.lessons.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.lessons.isEmpty
                      ? const _EmptyLessons()
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
                              onTap: () => onPick(state.lessons[i]),
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
  final VoidCallback onTap;
  const _CategoryCard({
    required this.item,
    required this.index,
    required this.onTap,
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
                        ? 'Offline ready'
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
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                alignment: Alignment.topRight,
                padding: const EdgeInsets.all(12),
                child: const CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0x55000000),
                  child: Icon(Icons.cloud_queue_rounded,
                      color: Colors.white, size: 14),
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

class _EmptyLessons extends StatelessWidget {
  const _EmptyLessons();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('No lessons available yet.', style: AppTextStyles.caption),
    );
  }
}
