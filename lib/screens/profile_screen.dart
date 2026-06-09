import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback onSettings;
  const ProfileScreen({super.key, required this.onSettings});

  static const _badges = [
    ('🌸', 'First Step', AppColors.sakuraSoft),
    ('🔥', '7 Days', AppColors.sakuraSoft),
    ('🏆', '100 XP', AppColors.goldSoft),
    ('🎴', 'Card Pro', AppColors.primarySoft),
    ('⚡', 'Speed', AppColors.skySoft),
    ('🌟', 'Star', AppColors.goldSoft),
    ('🧠', 'Brainy', AppColors.matchaSoft),
    ('🔒', 'Locked', AppColors.inputBg),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.only(bottom: 96), children: [
      Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
        decoration: const BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Profile',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                GestureDetector(
                  onTap: onSettings,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.settings_outlined,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4), width: 4),
              ),
              alignment: Alignment.center,
              child: const Text('👩‍🎓', style: TextStyle(fontSize: 44)),
            ),
            const SizedBox(height: 12),
            const Text('Mai Tanaka',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20)),
            Text('@mai_chan · JLPT N5 Learner',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('⭐', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                const Text('Level 7',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
                const SizedBox(width: 6),
                Text('· 2,480 XP',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11)),
              ]),
            ),
          ]),
        ),
      ),
      Transform.translate(
        offset: const Offset(0, -28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.card,
            ),
            child: Row(children: [
              _stat(Icons.local_fire_department_rounded, AppColors.sakura,
                  AppColors.sakuraSoft, '14', 'Day streak'),
              _stat(Icons.menu_book_rounded, AppColors.primary,
                  AppColors.primarySoft, '342', 'Words'),
              _stat(Icons.emoji_events_rounded, AppColors.matcha,
                  AppColors.matchaSoft, '18', 'Lessons'),
            ]),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Achievements', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 96,
            children: _badges
                .map((b) => Column(children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                            color: b.$3,
                            borderRadius: BorderRadius.circular(AppRadius.lg)),
                        alignment: Alignment.center,
                        child: Text(b.$1, style: const TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(height: 6),
                      Text(b.$2,
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w600)),
                    ]))
                .toList(),
          ),
          const SizedBox(height: 20),
          Text('Weekly Goal', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          _weeklyGoal(),
        ]),
      ),
    ]);
  }

  Widget _weeklyGoal() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
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
                Text(
                  '4 of 7 days complete',
                  style:
                      AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: 4 / 7,
                minHeight: 8,
                backgroundColor: AppColors.inputBg,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _GoalDay(label: '✓', completed: true),
                _GoalDay(label: '✓', completed: true),
                _GoalDay(label: '✓', completed: true),
                _GoalDay(label: '✓', completed: true),
                _GoalDay(label: 'F'),
                _GoalDay(label: 'S'),
                _GoalDay(label: 'S'),
              ],
            ),
          ],
        ),
      );

  Widget _stat(IconData icon, Color fg, Color bg, String value, String label) =>
      Expanded(
        child: Column(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Icon(icon, color: fg, size: 18),
          ),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.mute,
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
        ]),
      );
}

class _GoalDay extends StatelessWidget {
  final String label;
  final bool completed;

  const _GoalDay({
    required this.label,
    this.completed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: completed ? AppColors.primary : AppColors.inputBg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: completed ? Colors.white : AppColors.mute,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}
