import '../../auth/models/auth_models.dart';

class ProfileAchievement {
  final String icon;
  final String title;
  final String description;
  final int current;
  final int target;

  const ProfileAchievement({
    required this.icon,
    required this.title,
    required this.description,
    required this.current,
    required this.target,
  });

  bool get unlocked => current >= target;
  double get progress =>
      target <= 0 ? 1.0 : (current / target).clamp(0, 1).toDouble();
}

class ProfileSummary {
  final UserModel user;
  final int streakDays;
  final int learnedWords;
  final int savedWords;
  final int completedLessons;
  final int totalLessons;
  final int totalVocabulary;
  final int downloadedLessons;
  final int totalXp;
  final int level;
  final int flashcardSessions;
  final int weeklyCompletedDays;
  final int weeklyGoalDays;
  final DateTime? lastActivityAt;

  const ProfileSummary({
    required this.user,
    required this.streakDays,
    required this.learnedWords,
    required this.savedWords,
    required this.completedLessons,
    required this.totalLessons,
    required this.totalVocabulary,
    required this.downloadedLessons,
    required this.totalXp,
    required this.level,
    required this.flashcardSessions,
    required this.weeklyCompletedDays,
    required this.weeklyGoalDays,
    this.lastActivityAt,
  });

  String get displayName {
    if (user.name.trim().isNotEmpty) return user.name.trim();
    if (user.email.trim().isNotEmpty) return user.email.split('@').first;
    return 'Learner';
  }

  String get handle {
    final source = user.email.contains('@')
        ? user.email.split('@').first
        : displayName.toLowerCase();
    final normalized = source
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return '@${normalized.isEmpty ? 'learner' : normalized}';
  }

  String get roleLabel {
    final role = user.role.trim().isEmpty ? 'learner' : user.role.trim();
    return '${role[0].toUpperCase()}${role.substring(1)}';
  }

  String get providerLabel {
    switch (user.provider) {
      case 'google':
        return 'Google';
      case 'both':
        return 'Email + Google';
      case 'local':
      default:
        return 'Email';
    }
  }

  double get weeklyProgress {
    if (weeklyGoalDays <= 0) return 0;
    return (weeklyCompletedDays / weeklyGoalDays).clamp(0, 1).toDouble();
  }

  int get nextLevelXp => level * 250;

  List<ProfileAchievement> get achievements => [
        ProfileAchievement(
          icon: 'SA',
          title: 'First Step',
          description: 'Start learning',
          current: totalActivityCount,
          target: 1,
        ),
        ProfileAchievement(
          icon: '7D',
          title: '7 Days',
          description: 'Keep a weekly streak',
          current: streakDays,
          target: 7,
        ),
        ProfileAchievement(
          icon: 'XP',
          title: '100 XP',
          description: 'Earn practice XP',
          current: totalXp,
          target: 100,
        ),
        ProfileAchievement(
          icon: 'FC',
          title: 'Card Pro',
          description: 'Finish flashcards',
          current: flashcardSessions,
          target: 3,
        ),
        ProfileAchievement(
          icon: 'BM',
          title: 'Collector',
          description: 'Save vocabulary',
          current: savedWords,
          target: 10,
        ),
        ProfileAchievement(
          icon: 'JL',
          title: 'Scholar',
          description: 'Complete lessons',
          current: completedLessons,
          target: 5,
        ),
        ProfileAchievement(
          icon: 'JP',
          title: 'Brainy',
          description: 'Learn vocabulary',
          current: learnedWords,
          target: 50,
        ),
        ProfileAchievement(
          icon: 'DL',
          title: 'Offline',
          description: 'Download a lesson',
          current: downloadedLessons,
          target: 1,
        ),
      ];

  int get totalActivityCount =>
      flashcardSessions + completedLessons + learnedWords + savedWords;

  static UserModel guest() => const UserModel(
        id: '',
        email: '',
        name: 'Learner',
        role: 'learner',
        provider: 'local',
        emailVerified: false,
      );
}
