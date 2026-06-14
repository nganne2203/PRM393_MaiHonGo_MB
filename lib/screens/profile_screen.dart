import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/app_localizations.dart';
import '../features/profile/models/profile_summary.dart';
import '../features/profile/state/profile_provider.dart';
import '../shared/widgets/app_state_widgets.dart';
import '../theme/app_palette.dart';
import '../theme/tokens.dart';

class ProfileScreen extends ConsumerWidget {
  final VoidCallback onSettings;

  const ProfileScreen({super.key, required this.onSettings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileSummaryProvider);

    return profile.when(
      loading: () => AppLoadingState(message: context.tr('Loading profile...')),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: AppStatePlaceholder.error(
          title: context.tr('Profile could not load.'),
          message: error.toString(),
          onRetry: () => ref.invalidate(profileSummaryProvider),
        ),
      ),
      data: (summary) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileSummaryProvider);
          await ref.read(profileSummaryProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            _Header(summary: summary, onSettings: onSettings),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _StatsCard(summary: summary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SnapshotCard(summary: summary),
                  const SizedBox(height: 22),
                  Text(context.tr('Achievements'), style: context.h3),
                  const SizedBox(height: 12),
                  _AchievementsGrid(achievements: summary.achievements),
                  const SizedBox(height: 22),
                  Text(context.tr('Weekly Goal'), style: context.h3),
                  const SizedBox(height: 12),
                  _WeeklyGoal(summary: summary),
                  const SizedBox(height: 22),
                  Text(context.tr('Account'), style: context.h3),
                  const SizedBox(height: 12),
                  _AccountCard(summary: summary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ProfileSummary summary;
  final VoidCallback onSettings;

  const _Header({
    required this.summary,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      decoration: const BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('Profile'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                GestureDetector(
                  onTap: onSettings,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _Avatar(summary: summary),
            const SizedBox(height: 14),
            Text(
              summary.displayName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${summary.handle} · ${context.tr(summary.roleLabel)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.gold,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Level ${summary.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '· ${summary.totalXp} XP',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.74),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final ProfileSummary summary;

  const _Avatar({required this.summary});

  @override
  Widget build(BuildContext context) {
    final avatar = summary.user.avatar;

    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        shape: BoxShape.circle,
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.4), width: 4),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: avatar == null || avatar.isEmpty
          ? Text(
              _initials(summary.displayName),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            )
          : Image.network(
              avatar,
              width: 104,
              height: 104,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Text(
                _initials(summary.displayName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final ProfileSummary summary;

  const _StatsCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          _stat(
            context,
            Icons.local_fire_department_rounded,
            AppColors.sakura,
            AppColors.sakuraSoft,
            summary.streakDays.toString(),
            context.tr('Day streak'),
          ),
          _stat(
            context,
            Icons.menu_book_rounded,
            AppColors.primary,
            AppColors.primarySoft,
            summary.learnedWords.toString(),
            context.tr('Words'),
          ),
          _stat(
            context,
            Icons.emoji_events_rounded,
            AppColors.matcha,
            AppColors.matchaSoft,
            summary.completedLessons.toString(),
            context.tr('Lessons'),
          ),
        ],
      ),
    );
  }

  Widget _stat(
    BuildContext context,
    IconData icon,
    Color fg,
    Color bg,
    String value,
    String label,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: fg, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: context.colors.ink,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: context.colors.mute,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  final ProfileSummary summary;

  const _SnapshotCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Learning Snapshot'),
            style: context.bodyText.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniStat(context, 'Saved', summary.savedWords.toString()),
              _miniStat(
                  context, 'Offline', summary.downloadedLessons.toString()),
              _miniStat(
                context,
                'Vocabulary',
                summary.totalVocabulary.toString(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 16, color: AppColors.mute),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _lastActivityLabel(context, summary.lastActivityAt),
                  style: context.captionText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(BuildContext context, String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: context.colors.input,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: context.h3,
            ),
            Text(context.tr(label), style: context.captionText),
          ],
        ),
      ),
    );
  }
}

class _AchievementsGrid extends StatelessWidget {
  final List<ProfileAchievement> achievements;

  const _AchievementsGrid({required this.achievements});

  static const _colors = [
    AppColors.sakuraSoft,
    AppColors.sakuraSoft,
    AppColors.goldSoft,
    AppColors.primarySoft,
    AppColors.skySoft,
    AppColors.goldSoft,
    AppColors.matchaSoft,
    AppColors.inputBg,
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: achievements.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 112,
      ),
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        final unlocked = achievement.unlocked;
        return Opacity(
          opacity: unlocked ? 1 : 0.56,
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: _colors[index % _colors.length],
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                alignment: Alignment.center,
                child: unlocked
                    ? Text(
                        achievement.icon,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      )
                    : const Icon(Icons.lock_rounded, color: AppColors.mute),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr(achievement.title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
              ),
              Text(
                '${achievement.current.clamp(0, achievement.target)}/${achievement.target}',
                style: const TextStyle(
                  color: AppColors.mute,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeeklyGoal extends StatelessWidget {
  final ProfileSummary summary;

  const _WeeklyGoal({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Icon(
                  Icons.track_changes_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.isVietnamese
                      ? '${summary.weeklyCompletedDays}/${summary.weeklyGoalDays} ngày hoàn thành'
                      : '${summary.weeklyCompletedDays} of ${summary.weeklyGoalDays} days complete',
                  style: context.bodyText.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: summary.weeklyProgress,
              minHeight: 8,
              backgroundColor: context.colors.input,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final completed = index < summary.weeklyCompletedDays;
              return _GoalDay(
                label: _weekdayLabel(index),
                completed: completed,
                muted: index >= summary.weeklyGoalDays,
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final ProfileSummary summary;

  const _AccountCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          _accountRow(
            context,
            Icons.mail_outline_rounded,
            'Email',
            summary.user.email,
          ),
          const Divider(height: 20),
          _accountRow(
            context,
            Icons.login_rounded,
            'Sign-in',
            summary.providerLabel,
          ),
          const Divider(height: 20),
          _accountRow(
            context,
            summary.user.emailVerified
                ? Icons.verified_rounded
                : Icons.info_outline_rounded,
            'Email status',
            summary.user.emailVerified ? 'Verified' : 'Not verified',
          ),
        ],
      ),
    );
  }

  Widget _accountRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Text(context.tr(label), style: context.captionText),
        const Spacer(),
        Flexible(
          child: Text(
            value.isEmpty ? context.tr('Not available') : context.tr(value),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: context.bodyText.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _GoalDay extends StatelessWidget {
  final String label;
  final bool completed;
  final bool muted;

  const _GoalDay({
    required this.label,
    this.completed = false,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = completed
        ? AppColors.primary
        : muted
            ? context.colors.line
            : context.colors.input;
    final fg = completed ? Colors.white : context.colors.mute;

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        completed ? '✓' : label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'L';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _weekdayLabel(int index) {
  const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  return labels[index.clamp(0, labels.length - 1)];
}

String _lastActivityLabel(BuildContext context, DateTime? value) {
  if (value == null) return context.tr('No learning activity recorded yet.');
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(value.year, value.month, value.day);
  final days = today.difference(date).inDays;
  if (days <= 0) return context.tr('Last activity today.');
  if (days == 1) return context.tr('Last activity yesterday.');
  if (context.l10n.isVietnamese) return 'Hoạt động gần nhất $days ngày trước.';
  return 'Last activity $days days ago.';
}
