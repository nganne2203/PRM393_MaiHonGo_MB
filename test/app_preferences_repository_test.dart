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
    await repository.setWeeklyGoalDays(5);

    final settings = await repository.getSettings();
    expect(settings.darkModeEnabled, isTrue);
    expect(settings.notificationsEnabled, isFalse);
    expect(settings.soundEffectsEnabled, isFalse);
    expect(settings.languageCode, 'vi');
    expect(settings.languageLabel, 'Vietnamese');
    expect(settings.reminderMinutes, 450);
    expect(settings.reminderLabel, '07:30');
    expect(settings.weeklyGoalDays, 5);
  });
}
