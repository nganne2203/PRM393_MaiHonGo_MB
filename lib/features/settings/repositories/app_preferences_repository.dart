import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final bool darkModeEnabled;
  final bool notificationsEnabled;
  final bool soundEffectsEnabled;

  const AppSettings({
    required this.darkModeEnabled,
    required this.notificationsEnabled,
    required this.soundEffectsEnabled,
  });

  const AppSettings.defaults()
      : darkModeEnabled = false,
        notificationsEnabled = true,
        soundEffectsEnabled = true;

  AppSettings copyWith({
    bool? darkModeEnabled,
    bool? notificationsEnabled,
    bool? soundEffectsEnabled,
  }) {
    return AppSettings(
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
    );
  }
}

class AppPreferencesRepository {
  static const _onboardingCompletedKey = 'onboarding_completed';
  static const _darkModeKey = 'settings_dark_mode';
  static const _notificationsKey = 'settings_notifications';
  static const _soundEffectsKey = 'settings_sound_effects';

  final Future<SharedPreferences> _prefsFuture;

  AppPreferencesRepository({Future<SharedPreferences>? prefs})
      : _prefsFuture = prefs ?? SharedPreferences.getInstance();

  Future<bool> isOnboardingCompleted() async {
    final prefs = await _prefsFuture;
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    final prefs = await _prefsFuture;
    await prefs.setBool(_onboardingCompletedKey, completed);
  }

  Future<AppSettings> getSettings() async {
    final prefs = await _prefsFuture;
    return AppSettings(
      darkModeEnabled: prefs.getBool(_darkModeKey) ??
          const AppSettings.defaults().darkModeEnabled,
      notificationsEnabled: prefs.getBool(_notificationsKey) ??
          const AppSettings.defaults().notificationsEnabled,
      soundEffectsEnabled: prefs.getBool(_soundEffectsKey) ??
          const AppSettings.defaults().soundEffectsEnabled,
    );
  }

  Future<AppSettings> setDarkModeEnabled(bool enabled) async {
    final prefs = await _prefsFuture;
    await prefs.setBool(_darkModeKey, enabled);
    final current = await getSettings();
    return current.copyWith(darkModeEnabled: enabled);
  }

  Future<AppSettings> setNotificationsEnabled(bool enabled) async {
    final prefs = await _prefsFuture;
    await prefs.setBool(_notificationsKey, enabled);
    final current = await getSettings();
    return current.copyWith(notificationsEnabled: enabled);
  }

  Future<AppSettings> setSoundEffectsEnabled(bool enabled) async {
    final prefs = await _prefsFuture;
    await prefs.setBool(_soundEffectsKey, enabled);
    final current = await getSettings();
    return current.copyWith(soundEffectsEnabled: enabled);
  }
}
