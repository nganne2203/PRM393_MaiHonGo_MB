import 'package:flutter_test/flutter_test.dart';
import 'package:maihongo/features/auth/models/auth_models.dart';
import 'package:maihongo/features/profile/models/profile_summary.dart';

void main() {
  test('ProfileSummary derives display labels and weekly progress', () {
    const summary = ProfileSummary(
      user: UserModel(
        id: 'user-1',
        email: 'ngan.nguyen@example.com',
        name: 'Ngan Nguyen',
        role: 'learner',
        provider: 'local',
        emailVerified: true,
      ),
      streakDays: 4,
      learnedWords: 55,
      savedWords: 12,
      completedLessons: 6,
      totalLessons: 8,
      totalVocabulary: 80,
      downloadedLessons: 1,
      totalXp: 325,
      level: 2,
      flashcardSessions: 3,
      weeklyCompletedDays: 3,
      weeklyGoalDays: 5,
    );

    expect(summary.displayName, 'Ngan Nguyen');
    expect(summary.handle, '@ngan_nguyen');
    expect(summary.providerLabel, 'Email');
    expect(summary.weeklyProgress, 0.6);
    expect(summary.achievements.where((item) => item.unlocked), hasLength(7));
  });
}
