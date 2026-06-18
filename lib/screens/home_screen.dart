import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/app_localizations.dart';
import '../features/dashboard/models/dashboard_summary.dart';
import '../features/dashboard/state/dashboard_controller.dart';
import '../theme/app_theme.dart';
import '../theme/app_palette.dart';
import '../theme/tokens.dart';

class HomeScreen extends ConsumerWidget {
  final ValueChanged<String?> onStartLesson;
  final VoidCallback onSeeAllPractice;
  final ValueChanged<ContinueLearning?> onStartQuiz;
  final ValueChanged<ContinueLearning?> onStartSpeaking;
  final ValueChanged<ContinueLearning?> onStartListening;
  final ValueChanged<ContinueLearning?> onStartWriting;
  final VoidCallback onOpenSaved;

  const HomeScreen({
    super.key,
    required this.onStartLesson,
    required this.onSeeAllPractice,
    required this.onStartQuiz,
    required this.onStartSpeaking,
    required this.onStartListening,
    required this.onStartWriting,
    required this.onOpenSaved,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final summary = state.summary;

    if (state.status == DashboardStatus.loading && summary == null) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    if (state.status == DashboardStatus.error && summary == null) {
      return SafeArea(
        child: _ErrorState(
          message: state.message ?? context.tr('Unable to load dashboard.'),
          onRetry: () => ref.read(dashboardProvider.notifier).load(),
        ),
      );
    }

    if (summary == null) {
      return const SafeArea(child: SizedBox.shrink());
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () =>
            ref.read(dashboardProvider.notifier).load(refresh: true),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            _heroHeader(context, summary),
            if (state.status == DashboardStatus.error && state.message != null)
              _StatusBanner(
                message: state.message!,
                onRetry: () => ref.read(dashboardProvider.notifier).load(),
              ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(context.tr('Continue Learning'), style: context.h3),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _continueLearningCard(context, summary.continueLearning),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.tr('Practice'), style: context.h3),
                  TextButton(
                    onPressed: onSeeAllPractice,
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      context.tr('See all'),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _practiceGrid(context, summary),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(context.tr('Recommended for you'), style: context.h3),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _recommendedCourses(context, summary.recommendedCourses),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _heroHeader(BuildContext context, DashboardSummary summary) =>
      Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0x33FFFFFF),
                    backgroundImage: summary.user.avatarUrl.isEmpty
                        ? null
                        : NetworkImage(summary.user.avatarUrl),
                    child: summary.user.avatarUrl.isEmpty
                        ? const Icon(Icons.school_rounded, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.isVietnamese
                              ? 'Xin chào,'
                              : '\u3053\u3093\u306b\u3061\u306f,',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          summary.user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.notifications_none_rounded,
                      color: Colors.white),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _statPill(
                      Icons.local_fire_department_rounded,
                      'Streak',
                      context.l10n.isVietnamese
                          ? '${summary.stats.streakDays} ngày'
                          : '${summary.stats.streakDays} days',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statPill(
                      Icons.flash_on_rounded,
                      context.tr('XP Today'),
                      summary.stats.xpToday.toString(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _goalCard(context, summary.stats),
            ],
          ),
        ),
      );

  Widget _continueLearningCard(BuildContext context, ContinueLearning? lesson) {
    final lessonId = lesson?.lessonId;
    final hasLesson = lesson != null;

    return GestureDetector(
      onTap: () => onStartLesson(lessonId),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppGradients.sakura,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: AppColors.sakura.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              alignment: Alignment.center,
              child: Text(
                '\u685c',
                style: AppTextStyles.jp(
                  26,
                  color: Colors.white,
                  w: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasLesson
                        ? '${lesson.level} · ${context.tr('Lesson')} ${lesson.lessonNumber}'
                        : context.tr('Lesson'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    hasLesson && lesson.title.isNotEmpty
                        ? lesson.title
                        : context.tr('Start your first lesson'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: lesson?.progressValue ?? 0,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: Icon(Icons.play_arrow_rounded, color: AppColors.sakura),
            ),
          ],
        ),
      ),
    );
  }

  Widget _practiceGrid(BuildContext context, DashboardSummary summary) {
    final practice = summary.practiceSummary;
    final lessonId = summary.continueLearning?.lessonId;

    return Column(
      children: [
        Row(
          children: [
            _practiceCard(
              context: context,
              icon: Icons.auto_stories_rounded,
              iconBg: AppColors.primarySoft,
              iconFg: AppColors.primary,
              title: context.tr('Flashcards'),
              subtitle: context.l10n.isVietnamese
                  ? 'Ôn ${practice.flashcardCount} thẻ'
                  : 'Review ${practice.flashcardCount} cards',
              onTap: () => onStartLesson(lessonId),
            ),
            const SizedBox(width: 12),
            _practiceCard(
              context: context,
              icon: Icons.psychology_rounded,
              iconBg: AppColors.skySoft,
              iconFg: AppColors.sky,
              title: context.tr('Quiz'),
              subtitle: context.l10n.isVietnamese
                  ? '${practice.quizQuestionCount} câu hỏi'
                  : '${practice.quizQuestionCount} questions',
              onTap: () => onStartQuiz(summary.continueLearning),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _practiceCard(
              context: context,
              icon: Icons.menu_book_rounded,
              iconBg: AppColors.matchaSoft,
              iconFg: AppColors.matcha,
              title: context.tr('Vocabulary'),
              subtitle: context.l10n.isVietnamese
                  ? '${practice.vocabularyCount} từ'
                  : '${practice.vocabularyCount} words',
              onTap: onSeeAllPractice,
            ),
            const SizedBox(width: 12),
            _practiceCard(
              context: context,
              icon: Icons.mic_rounded,
              iconBg: AppColors.goldSoft,
              iconFg: AppColors.gold,
              title: context.tr('Speaking'),
              subtitle: context.tr(practice.speakingLabel),
              onTap: () => onStartSpeaking(summary.continueLearning),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _practiceCard(
              context: context,
              icon: Icons.bookmark_rounded,
              iconBg: AppColors.sakuraSoft,
              iconFg: AppColors.sakura,
              title: context.tr('Saved'),
              subtitle: context.l10n.isVietnamese
                  ? '${practice.savedBookmarkCount} từ đã lưu'
                  : '${practice.savedBookmarkCount} bookmarks',
              onTap: onOpenSaved,
            ),
            const SizedBox(width: 12),
            _practiceCard(
              context: context,
              icon: Icons.headphones_rounded,
              iconBg: AppColors.goldSoft,
              iconFg: AppColors.gold,
              title: context.tr('Listening'),
              subtitle: context.tr('Audio practice'),
              onTap: () => onStartListening(summary.continueLearning),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _practiceCard(
              context: context,
              icon: Icons.edit_note_rounded,
              iconBg: AppColors.primarySoft,
              iconFg: AppColors.primary,
              title: context.tr('Writing'),
              subtitle: context.tr('Practice sentences'),
              onTap: () => onStartWriting(summary.continueLearning),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }

  Widget _recommendedCourses(
    BuildContext context,
    List<RecommendedCourse> courses,
  ) {
    if (courses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Text(
          context.tr('No recommendations yet.'),
          style: context.captionText,
        ),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < courses.length; index++) ...[
          _recommendedCard(
            context: context,
            icon: _recommendedIcon(index),
            iconBg: _recommendedGradient(index),
            title: courses[index].title,
            subtitle: context.l10n.isVietnamese
                ? '${courses[index].wordCount} từ · hoàn thành ${courses[index].progressPercent}%'
                : '${courses[index].wordCount} words · ${courses[index].progressPercent}% complete',
          ),
          if (index < courses.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _recommendedCard({
    required BuildContext context,
    required IconData icon,
    required LinearGradient iconBg,
    required String title,
    required String subtitle,
  }) =>
      GestureDetector(
        onTap: onSeeAllPractice,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(16),
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
                decoration: BoxDecoration(
                  gradient: iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.bodyText.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: context.captionText),
                  ],
                ),
              ),
              const Icon(Icons.emoji_events_outlined,
                  color: AppColors.gold, size: 22),
            ],
          ),
        ),
      );

  Widget _practiceCard({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required Color iconFg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: iconFg, size: 22),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: context.bodyText.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: context.captionText),
              ],
            ),
          ),
        ),
      );

  Widget _statPill(IconData icon, String label, String value) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: AppColors.gold, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _goalCard(BuildContext context, DashboardStats stats) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('Daily Goal'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  context.l10n.isVietnamese
                      ? '${stats.dailyGoalCompleted} / ${stats.dailyGoalTarget} từ'
                      : '${stats.dailyGoalCompleted} / ${stats.dailyGoalTarget} words',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: stats.dailyGoalProgress,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation(AppColors.gold),
              ),
            ),
          ],
        ),
      );

  IconData _recommendedIcon(int index) {
    const icons = [
      Icons.local_florist_rounded,
      Icons.spa_rounded,
      Icons.chrome_reader_mode_rounded,
      Icons.school_rounded,
      Icons.menu_book_rounded,
    ];
    return icons[index % icons.length];
  }

  LinearGradient _recommendedGradient(int index) {
    const gradients = [
      AppGradients.sakura,
      AppGradients.matcha,
      AppGradients.primary,
      AppGradients.sky,
      AppGradients.warm,
    ];
    return gradients[index % gradients.length];
  }
}

class _StatusBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _StatusBanner({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.sakuraSoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.sakura, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.sakura,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(onPressed: onRetry, child: Text(context.tr('Retry'))),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: AppColors.sakura, size: 36),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.bodyText.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: Text(context.tr('Retry'))),
          ],
        ),
      ),
    );
  }
}
