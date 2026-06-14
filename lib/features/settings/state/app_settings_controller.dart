import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/app_preferences_repository.dart';

final appPreferencesRepositoryProvider =
    Provider<AppPreferencesRepository>((ref) => AppPreferencesRepository());

final appSettingsControllerProvider =
    StateNotifierProvider<AppSettingsController, AsyncValue<AppSettings>>(
  (ref) => AppSettingsController(ref.watch(appPreferencesRepositoryProvider)),
);

class AppSettingsController extends StateNotifier<AsyncValue<AppSettings>> {
  final AppPreferencesRepository _repository;

  AppSettingsController(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  AppSettings get current => state.valueOrNull ?? const AppSettings.defaults();

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.getSettings);
  }

  Future<void> setDarkModeEnabled(bool enabled) {
    return _save(() => _repository.setDarkModeEnabled(enabled));
  }

  Future<void> setNotificationsEnabled(bool enabled) {
    return _save(() => _repository.setNotificationsEnabled(enabled));
  }

  Future<void> setSoundEffectsEnabled(bool enabled) {
    return _save(() => _repository.setSoundEffectsEnabled(enabled));
  }

  Future<void> setLanguageCode(String code) {
    return _save(() => _repository.setLanguageCode(code));
  }

  Future<void> setReminderMinutes(int minutes) {
    return _save(() => _repository.setReminderMinutes(minutes));
  }

  Future<void> setWeeklyGoalDays(int days) {
    return _save(() => _repository.setWeeklyGoalDays(days));
  }

  Future<void> _save(Future<AppSettings> Function() action) async {
    final previous = current;
    state = AsyncValue.data(previous);
    state = await AsyncValue.guard(action);
  }
}
