import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final bool darkModeEnabled;
  final bool notificationsEnabled;
  final bool soundEffectsEnabled;
  final String languageCode;
  final int reminderMinutes;
  final int weeklyGoalDays;

  const AppSettings({
    required this.darkModeEnabled,
    required this.notificationsEnabled,
    required this.soundEffectsEnabled,
    required this.languageCode,
    required this.reminderMinutes,
    required this.weeklyGoalDays,
  });

  const AppSettings.defaults()
      : darkModeEnabled = false,
        notificationsEnabled = true,
        soundEffectsEnabled = true,
        languageCode = 'en',
        reminderMinutes = 20 * 60,
        weeklyGoalDays = 7;

  String get languageLabel {
    switch (languageCode) {
      case 'vi':
        return 'Vietnamese';
      case 'ja':
        return 'Japanese';
      case 'en':
      default:
        return 'English';
    }
  }

  String get reminderLabel {
    final hour = reminderMinutes ~/ 60;
    final minute = reminderMinutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  AppSettings copyWith({
    bool? darkModeEnabled,
    bool? notificationsEnabled,
    bool? soundEffectsEnabled,
    String? languageCode,
    int? reminderMinutes,
    int? weeklyGoalDays,
  }) {
    return AppSettings(
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      languageCode: languageCode ?? this.languageCode,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      weeklyGoalDays: weeklyGoalDays ?? this.weeklyGoalDays,
    );
  }
}

class AppPreferencesRepository {
  static const _onboardingCompletedKey = 'onboarding_completed';
  static const _darkModeKey = 'settings_dark_mode';
  static const _notificationsKey = 'settings_notifications';
  static const _soundEffectsKey = 'settings_sound_effects';
  static const _languageCodeKey = 'settings_language_code';
  static const _reminderMinutesKey = 'settings_reminder_minutes';
  static const _weeklyGoalDaysKey = 'settings_weekly_goal_days';

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
      languageCode: prefs.getString(_languageCodeKey) ??
          const AppSettings.defaults().languageCode,
      reminderMinutes: prefs.getInt(_reminderMinutesKey) ??
          const AppSettings.defaults().reminderMinutes,
      weeklyGoalDays: prefs.getInt(_weeklyGoalDaysKey) ??
          const AppSettings.defaults().weeklyGoalDays,
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

  Future<AppSettings> setLanguageCode(String code) async {
    final normalized = _supportedLanguageCodes.contains(code) ? code : 'en';
    final prefs = await _prefsFuture;
    await prefs.setString(_languageCodeKey, normalized);
    final current = await getSettings();
    return current.copyWith(languageCode: normalized);
  }

  Future<AppSettings> setReminderMinutes(int minutes) async {
    final normalized = minutes.clamp(0, 23 * 60 + 59).toInt();
    final prefs = await _prefsFuture;
    await prefs.setInt(_reminderMinutesKey, normalized);
    final current = await getSettings();
    return current.copyWith(reminderMinutes: normalized);
  }

  Future<AppSettings> setWeeklyGoalDays(int days) async {
    final normalized = days.clamp(1, 7).toInt();
    final prefs = await _prefsFuture;
    await prefs.setInt(_weeklyGoalDaysKey, normalized);
    final current = await getSettings();
    return current.copyWith(weeklyGoalDays: normalized);
  }

  static const _supportedLanguageCodes = {'en', 'vi', 'ja'};
}
