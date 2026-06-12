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

    final settings = await repository.getSettings();
    expect(settings.darkModeEnabled, isTrue);
    expect(settings.notificationsEnabled, isFalse);
    expect(settings.soundEffectsEnabled, isFalse);
  });
}
