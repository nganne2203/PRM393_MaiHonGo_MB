import 'package:flutter_test/flutter_test.dart';
import 'package:maihongo/features/settings/repositories/app_preferences_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppPreferencesRepository persists onboarding completion', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = AppPreferencesRepository();

    expect(await repository.isOnboardingCompleted(), isFalse);

    await repository.setOnboardingCompleted(true);

    expect(await repository.isOnboardingCompleted(), isTrue);
  });

  test('AppPreferencesRepository persists settings toggles', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = AppPreferencesRepository();

    expect((await repository.getSettings()).notificationsEnabled, isTrue);

    await repository.setDarkModeEnabled(true);
    await repository.setNotificationsEnabled(false);
    await repository.setSoundEffectsEnabled(false);
    await repository.setLanguageCode('vi');
    await repository.setReminderMinutes(7 * 60 + 30);
    await repository.setNotificationPlan('weekdays');
    await repository.setSoundEffectPack('focus');
    await repository.setSoundEffectVolume(80);
    await repository.setWeeklyGoalDays(5);
    await repository.setDailyWordGoal(20);
    await repository.setDailyStudyMinutes(30);

    final settings = await repository.getSettings();
    expect(settings.darkModeEnabled, isTrue);
    expect(settings.notificationsEnabled, isFalse);
    expect(settings.soundEffectsEnabled, isFalse);
    expect(settings.languageCode, 'vi');
    expect(settings.languageLabel, 'Vietnamese');
    expect(settings.reminderMinutes, 450);
    expect(settings.reminderLabel, '07:30');
    expect(settings.notificationPlan, 'weekdays');
    expect(settings.notificationPlanLabel, 'Weekdays only');
    expect(settings.soundEffectPack, 'focus');
    expect(settings.soundEffectPackLabel, 'Focus');
    expect(settings.soundEffectVolume, 80);
    expect(settings.weeklyGoalDays, 5);
    expect(settings.dailyWordGoal, 20);
    expect(settings.dailyStudyMinutes, 30);
  });

  test('AppPreferencesRepository normalizes advanced settings', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = AppPreferencesRepository();

    await repository.setNotificationPlan('unknown');
    await repository.setSoundEffectPack('unknown');
    await repository.setSoundEffectVolume(999);
    await repository.setDailyWordGoal(0);
    await repository.setDailyStudyMinutes(999);

    final settings = await repository.getSettings();
    expect(settings.notificationPlan,
        const AppSettings.defaults().notificationPlan);
    expect(
        settings.soundEffectPack, const AppSettings.defaults().soundEffectPack);
    expect(settings.soundEffectVolume, 100);
    expect(settings.dailyWordGoal, 1);
    expect(settings.dailyStudyMinutes, 120);
  });
}
