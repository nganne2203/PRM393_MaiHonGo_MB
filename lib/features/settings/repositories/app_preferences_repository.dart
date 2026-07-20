import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final bool darkModeEnabled;
  final bool notificationsEnabled;
  final bool soundEffectsEnabled;
  final String languageCode;
  final int reminderMinutes;
  final String notificationPlan;
  final String soundEffectPack;
  final int soundEffectVolume;
  final int weeklyGoalDays;
  final int dailyWordGoal;
  final int dailyStudyMinutes;

  const AppSettings({
    required this.darkModeEnabled,
    required this.notificationsEnabled,
    required this.soundEffectsEnabled,
    required this.languageCode,
    required this.reminderMinutes,
    required this.notificationPlan,
    required this.soundEffectPack,
    required this.soundEffectVolume,
    required this.weeklyGoalDays,
    required this.dailyWordGoal,
    required this.dailyStudyMinutes,
  });

  const AppSettings.defaults()
      : darkModeEnabled = false,
        notificationsEnabled = true,
        soundEffectsEnabled = true,
        languageCode = 'en',
        reminderMinutes = 20 * 60,
        notificationPlan = 'daily',
        soundEffectPack = 'sakura',
        soundEffectVolume = 70,
        weeklyGoalDays = 7,
        dailyWordGoal = 10,
        dailyStudyMinutes = 15;

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

  String get notificationPlanLabel {
    switch (notificationPlan) {
      case 'weekdays':
        return 'Weekdays only';
      case 'streak':
        return 'Streak rescue';
      case 'daily':
      default:
        return 'Every day';
    }
  }

  String get soundEffectPackLabel {
    switch (soundEffectPack) {
      case 'minimal':
        return 'Minimal';
      case 'focus':
        return 'Focus';
      case 'sakura':
      default:
        return 'Sakura pop';
    }
  }

  AppSettings copyWith({
    bool? darkModeEnabled,
    bool? notificationsEnabled,
    bool? soundEffectsEnabled,
    String? languageCode,
    int? reminderMinutes,
    String? notificationPlan,
    String? soundEffectPack,
    int? soundEffectVolume,
    int? weeklyGoalDays,
    int? dailyWordGoal,
    int? dailyStudyMinutes,
  }) {
    return AppSettings(
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      languageCode: languageCode ?? this.languageCode,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      notificationPlan: notificationPlan ?? this.notificationPlan,
      soundEffectPack: soundEffectPack ?? this.soundEffectPack,
      soundEffectVolume: soundEffectVolume ?? this.soundEffectVolume,
      weeklyGoalDays: weeklyGoalDays ?? this.weeklyGoalDays,
      dailyWordGoal: dailyWordGoal ?? this.dailyWordGoal,
      dailyStudyMinutes: dailyStudyMinutes ?? this.dailyStudyMinutes,
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
  static const _notificationPlanKey = 'settings_notification_plan';
  static const _soundEffectPackKey = 'settings_sound_effect_pack';
  static const _soundEffectVolumeKey = 'settings_sound_effect_volume';
  static const _weeklyGoalDaysKey = 'settings_weekly_goal_days';
  static const _dailyWordGoalKey = 'settings_daily_word_goal';
  static const _dailyStudyMinutesKey = 'settings_daily_study_minutes';

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
      languageCode: _normalizeLanguageCode(prefs.getString(_languageCodeKey)),
      reminderMinutes: prefs.getInt(_reminderMinutesKey) ??
          const AppSettings.defaults().reminderMinutes,
      notificationPlan:
          _normalizeNotificationPlan(prefs.getString(_notificationPlanKey)),
      soundEffectPack:
          _normalizeSoundEffectPack(prefs.getString(_soundEffectPackKey)),
      soundEffectVolume: (prefs.getInt(_soundEffectVolumeKey) ??
              const AppSettings.defaults().soundEffectVolume)
          .clamp(0, 100)
          .toInt(),
      weeklyGoalDays: prefs.getInt(_weeklyGoalDaysKey) ??
          const AppSettings.defaults().weeklyGoalDays,
      dailyWordGoal: (prefs.getInt(_dailyWordGoalKey) ??
              const AppSettings.defaults().dailyWordGoal)
          .clamp(1, 50)
          .toInt(),
      dailyStudyMinutes: (prefs.getInt(_dailyStudyMinutesKey) ??
              const AppSettings.defaults().dailyStudyMinutes)
          .clamp(5, 120)
          .toInt(),
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

  Future<AppSettings> setNotificationPlan(String plan) async {
    final normalized = _normalizeNotificationPlan(plan);
    final prefs = await _prefsFuture;
    await prefs.setString(_notificationPlanKey, normalized);
    final current = await getSettings();
    return current.copyWith(notificationPlan: normalized);
  }

  Future<AppSettings> setSoundEffectPack(String pack) async {
    final normalized = _normalizeSoundEffectPack(pack);
    final prefs = await _prefsFuture;
    await prefs.setString(_soundEffectPackKey, normalized);
    final current = await getSettings();
    return current.copyWith(soundEffectPack: normalized);
  }

  Future<AppSettings> setSoundEffectVolume(int volume) async {
    final normalized = volume.clamp(0, 100).toInt();
    final prefs = await _prefsFuture;
    await prefs.setInt(_soundEffectVolumeKey, normalized);
    final current = await getSettings();
    return current.copyWith(soundEffectVolume: normalized);
  }

  Future<AppSettings> setWeeklyGoalDays(int days) async {
    final normalized = days.clamp(1, 7).toInt();
    final prefs = await _prefsFuture;
    await prefs.setInt(_weeklyGoalDaysKey, normalized);
    final current = await getSettings();
    return current.copyWith(weeklyGoalDays: normalized);
  }

  Future<AppSettings> setDailyWordGoal(int words) async {
    final normalized = words.clamp(1, 50).toInt();
    final prefs = await _prefsFuture;
    await prefs.setInt(_dailyWordGoalKey, normalized);
    final current = await getSettings();
    return current.copyWith(dailyWordGoal: normalized);
  }

  Future<AppSettings> setDailyStudyMinutes(int minutes) async {
    final normalized = minutes.clamp(5, 120).toInt();
    final prefs = await _prefsFuture;
    await prefs.setInt(_dailyStudyMinutesKey, normalized);
    final current = await getSettings();
    return current.copyWith(dailyStudyMinutes: normalized);
  }

  static const _supportedLanguageCodes = {'en', 'vi'};
  static const _supportedNotificationPlans = {'daily', 'weekdays'};
  static const _supportedSoundEffectPacks = {'sakura', 'minimal', 'focus'};

  static String _normalizeNotificationPlan(String? plan) {
    return _supportedNotificationPlans.contains(plan)
        ? plan!
        : const AppSettings.defaults().notificationPlan;
  }

  static String _normalizeLanguageCode(String? code) {
    return _supportedLanguageCodes.contains(code) ? code! : 'en';
  }

  static String _normalizeSoundEffectPack(String? pack) {
    return _supportedSoundEffectPacks.contains(pack)
        ? pack!
        : const AppSettings.defaults().soundEffectPack;
  }
}
