import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onStartLesson;
  final VoidCallback onSeeAllPractice;
  final VoidCallback onStartQuiz;
  final VoidCallback onStartSpeaking;
  final VoidCallback onOpenSaved;

  const HomeScreen({
    super.key,
    required this.onStartLesson,
    required this.onSeeAllPractice,
    required this.onStartQuiz,
    required this.onStartSpeaking,
    required this.onOpenSaved,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          _heroHeader(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('Continue Learning', style: AppTextStyles.h3),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTap: onStartLesson,
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
                            'JLPT N5 · Lesson 7',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(
                            'Nature & Seasons',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: 0.62,
                              minHeight: 6,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.25),
                              valueColor:
                                  const AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.play_arrow_rounded,
                          color: AppColors.sakura),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Practice', style: AppTextStyles.h3),
                TextButton(
                  onPressed: onSeeAllPractice,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'See all',
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
            child: Column(
              children: [
                Row(
                  children: [
                    _practiceCard(
                      icon: Icons.auto_stories_rounded,
                      iconBg: AppColors.primarySoft,
                      iconFg: AppColors.primary,
                      title: 'Flashcards',
                      subtitle: 'Review 24 cards',
                      onTap: onStartLesson,
                    ),
                    const SizedBox(width: 12),
                    _practiceCard(
                      icon: Icons.psychology_rounded,
                      iconBg: AppColors.skySoft,
                      iconFg: AppColors.sky,
                      title: 'Quiz',
                      subtitle: '10 questions',
                      onTap: onStartQuiz,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _practiceCard(
                      icon: Icons.menu_book_rounded,
                      iconBg: AppColors.matchaSoft,
                      iconFg: AppColors.matcha,
                      title: 'Vocabulary',
                      subtitle: '800 words',
                      onTap: onSeeAllPractice,
                    ),
                    const SizedBox(width: 12),
                    _practiceCard(
                      icon: Icons.mic_rounded,
                      iconBg: AppColors.goldSoft,
                      iconFg: AppColors.gold,
                      title: 'Speaking',
                      subtitle: 'AI review',
                      onTap: onStartSpeaking,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _practiceCard(
                      icon: Icons.bookmark_rounded,
                      iconBg: AppColors.sakuraSoft,
                      iconFg: AppColors.sakura,
                      title: 'Saved',
                      subtitle: '32 bookmarks',
                      onTap: onOpenSaved,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('Recommended for you', style: AppTextStyles.h3),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _recommendedCard(
                  icon: Icons.local_florist_rounded,
                  iconBg: AppGradients.sakura,
                  title: 'JLPT N5',
                  subtitle: '800 words · 62% complete',
                ),
                const SizedBox(height: 12),
                _recommendedCard(
                  icon: Icons.spa_rounded,
                  iconBg: AppGradients.matcha,
                  title: 'JLPT N4',
                  subtitle: '1500 words · 24% complete',
                ),
                const SizedBox(height: 12),
                _recommendedCard(
                  icon: Icons.chrome_reader_mode_rounded,
                  iconBg: AppGradients.primary,
                  title: 'Kanji',
                  subtitle: '2136 words · 12% complete',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _heroHeader() => Container(
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
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0x33FFFFFF),
                    child: Icon(Icons.school_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\u3053\u3093\u306b\u3061\u306f,',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                        const Text(
                          'Mai-chan',
                          style: TextStyle(
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
                      '14 days',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statPill(Icons.flash_on_rounded, 'XP Today', '240'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _goalCard(),
            ],
          ),
        ),
      );

  Widget _recommendedCard({
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
            color: Colors.white,
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
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTextStyles.caption),
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
              color: Colors.white,
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
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.caption),
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
            Column(
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _goalCard() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Goal',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '24 / 30 words',
                  style: TextStyle(
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
                value: 0.8,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation(AppColors.gold),
              ),
            ),
          ],
        ),
      );
}
