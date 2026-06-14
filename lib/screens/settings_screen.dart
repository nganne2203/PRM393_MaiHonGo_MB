import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/app_localizations.dart';
import '../features/settings/repositories/app_preferences_repository.dart';
import '../features/settings/state/app_settings_controller.dart';
import '../theme/app_theme.dart';
import '../theme/app_palette.dart';
import '../theme/tokens.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final Future<void> Function() onLogout;

  const SettingsScreen({
    super.key,
    required this.onLogout,
  });

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  AppSettings _settings = const AppSettings.defaults();
  bool _saving = false;
  String? _message;

  bool get _dark => _settings.darkModeEnabled;
  bool get _notif => _settings.notificationsEnabled;
  bool get _audio => _settings.soundEffectsEnabled;

  Color get _background => context.colors.bg;
  Color get _surface => context.colors.surface;
  Color get _primaryText => context.colors.ink;
  Color get _secondaryText => context.colors.mute;

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(appSettingsControllerProvider);
    _settings = settingsState.valueOrNull ?? _settings;
    final loading = settingsState.isLoading;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Row(
              children: [
                BackButton(color: _primaryText),
                Text(
                  context.tr('Settings'),
                  style: AppTextStyles.h2.copyWith(color: _primaryText),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (loading || _saving)
              const LinearProgressIndicator(minHeight: 2)
            else
              const SizedBox(height: 2),
            if (_message != null) ...[
              const SizedBox(height: 12),
              _statusBanner(_message!),
            ],
            const SizedBox(height: 14),
            _section('PREFERENCES'),
            _toggleRow(
              Icons.dark_mode_outlined,
              AppColors.primary,
              AppColors.primarySoft,
              context.tr('Dark Mode'),
              context.tr(_dark
                  ? 'Dark appearance is active here'
                  : 'Easy on the eyes at night'),
              _dark,
              _setDarkMode,
            ),
            _toggleRow(
              Icons.notifications_outlined,
              AppColors.sakura,
              AppColors.sakuraSoft,
              context.tr('Notifications'),
              _notif
                  ? '${context.tr('Daily reminder at')} ${_settings.reminderLabel}'
                  : context.tr('Daily reminders are off'),
              _notif,
              _setNotifications,
            ),
            if (_notif)
              _navRow(
                Icons.schedule_rounded,
                AppColors.gold,
                AppColors.goldSoft,
                context.tr('Reminder Time'),
                _settings.reminderLabel,
                onTap: _chooseReminderTime,
              ),
            _toggleRow(
              Icons.volume_up_outlined,
              AppColors.matcha,
              AppColors.matchaSoft,
              context.tr('Sound Effects'),
              context.tr(
                _audio ? 'Audio feedback in app' : 'Feedback sounds are muted',
              ),
              _audio,
              _setSoundEffects,
            ),
            const SizedBox(height: 16),
            _section('LEARNING'),
            _navRow(
              Icons.language_rounded,
              AppColors.sky,
              AppColors.skySoft,
              context.tr('App Language'),
              context.tr(_settings.languageLabel),
              onTap: _chooseLanguage,
            ),
            _navRow(
              Icons.track_changes_rounded,
              AppColors.matcha,
              AppColors.matchaSoft,
              context.tr('Weekly Goal'),
              context.l10n.isVietnamese
                  ? '${_settings.weeklyGoalDays} ngày mỗi tuần'
                  : '${_settings.weeklyGoalDays} days per week',
              onTap: _chooseWeeklyGoal,
            ),
            _navRow(
              Icons.download_rounded,
              AppColors.primary,
              AppColors.primarySoft,
              context.tr('Offline Downloads'),
              context.tr('Manage downloaded lessons'),
              onTap: () => Navigator.pushNamed(context, '/offline-downloads'),
            ),
            const SizedBox(height: 16),
            _section('ACCOUNT'),
            _navRow(
              Icons.shield_outlined,
              AppColors.gold,
              AppColors.goldSoft,
              context.tr('Privacy & Security'),
              context.tr('Password, profile, and local data'),
              onTap: () => Navigator.pushNamed(context, '/privacy-security'),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _saving ? null : _confirmLogout,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.sakuraSoft),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_saving)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(
                        Icons.logout_rounded,
                        color: AppColors.sakura,
                        size: 16,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('Log Out'),
                      style: TextStyle(
                        color: AppColors.sakura,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Sakura · v1.0.0',
                style: TextStyle(color: _secondaryText, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String s) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
        child: Text(context.tr(s), style: context.overlineText),
      );

  Widget _statusBanner(String message) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );

  Future<void> _save(Future<void> Function() action, String message) async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await action();
      if (!mounted) return;
      setState(() {
        _settings =
            ref.read(appSettingsControllerProvider).valueOrNull ?? _settings;
        _message = context.tr(message);
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setDarkMode(bool value) {
    return _save(
      () => ref
          .read(appSettingsControllerProvider.notifier)
          .setDarkModeEnabled(value),
      value ? 'Dark mode enabled.' : 'Dark mode disabled.',
    );
  }

  Future<void> _setNotifications(bool value) {
    return _save(
      () => ref
          .read(appSettingsControllerProvider.notifier)
          .setNotificationsEnabled(value),
      value ? 'Study reminders enabled.' : 'Study reminders disabled.',
    );
  }

  Future<void> _setSoundEffects(bool value) {
    return _save(
      () => ref
          .read(appSettingsControllerProvider.notifier)
          .setSoundEffectsEnabled(value),
      value ? 'Sound effects enabled.' : 'Sound effects muted.',
    );
  }

  Future<void> _setLanguageCode(String code) {
    return _save(
      () => ref
          .read(appSettingsControllerProvider.notifier)
          .setLanguageCode(code),
      'Language preference updated.',
    );
  }

  Future<void> _setWeeklyGoalDays(int days) {
    return _save(
      () => ref
          .read(appSettingsControllerProvider.notifier)
          .setWeeklyGoalDays(days),
      'Weekly goal updated.',
    );
  }

  Future<void> _setReminderMinutes(int minutes) {
    return _save(
      () => ref
          .read(appSettingsControllerProvider.notifier)
          .setReminderMinutes(minutes),
      'Reminder time updated.',
    );
  }

  Future<void> _chooseLanguage() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _choiceTile(context, 'en', context.tr('English')),
            _choiceTile(context, 'vi', context.tr('Vietnamese')),
            _choiceTile(context, 'ja', context.tr('Japanese')),
          ],
        ),
      ),
    );
    if (selected == null || selected == _settings.languageCode) return;
    await _setLanguageCode(selected);
  }

  Future<void> _chooseWeeklyGoal() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: _surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _goalTile(context, 3, context.tr('Light pace')),
            _goalTile(context, 5, context.tr('Steady pace')),
            _goalTile(context, 7, context.tr('Daily practice')),
          ],
        ),
      ),
    );
    if (selected == null || selected == _settings.weeklyGoalDays) return;
    await _setWeeklyGoalDays(selected);
  }

  Future<void> _chooseReminderTime() async {
    final initial = TimeOfDay(
      hour: _settings.reminderMinutes ~/ 60,
      minute: _settings.reminderMinutes % 60,
    );
    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (selected == null) return;
    await _setReminderMinutes(selected.hour * 60 + selected.minute);
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Log out?')),
        content: Text(
          context.tr('You can sign back in with this account anytime.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('Log Out')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    await widget.onLogout();
  }

  Widget _choiceTile(BuildContext context, String code, String label) {
    final selected = _settings.languageCode == code;
    return ListTile(
      title: Text(label, style: TextStyle(color: _primaryText)),
      trailing: selected
          ? const Icon(Icons.check_rounded, color: AppColors.primary)
          : null,
      onTap: () => Navigator.pop(context, code),
    );
  }

  Widget _goalTile(BuildContext context, int days, String label) {
    final selected = _settings.weeklyGoalDays == days;
    return ListTile(
      title: Text(
        context.l10n.isVietnamese
            ? '$days ngày mỗi tuần'
            : '$days days per week',
        style: TextStyle(color: _primaryText),
      ),
      subtitle: Text(label, style: TextStyle(color: _secondaryText)),
      trailing: selected
          ? const Icon(Icons.check_rounded, color: AppColors.primary)
          : null,
      onTap: () => Navigator.pop(context, days),
    );
  }

  Widget _row(
    Widget leading,
    String label,
    String? sub,
    Widget trailing, {
    VoidCallback? onTap,
  }) {
    final content = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: _primaryText,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub,
                    style: TextStyle(
                      color: _secondaryText,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );

    if (onTap == null) return content;
    return GestureDetector(onTap: _saving ? null : onTap, child: content);
  }

  Widget _icon(IconData icon, Color fg, Color bg) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, color: fg, size: 18),
      );

  Widget _toggleRow(
    IconData icon,
    Color fg,
    Color bg,
    String label,
    String sub,
    bool value,
    ValueChanged<bool> onChange,
  ) =>
      _row(
        _icon(icon, fg, bg),
        label,
        sub,
        Switch(
          value: value,
          onChanged: _saving ? null : onChange,
          activeThumbColor: AppColors.primary,
        ),
      );

  Widget _navRow(
    IconData icon,
    Color fg,
    Color bg,
    String label,
    String sub, {
    VoidCallback? onTap,
  }) =>
      _row(
        _icon(icon, fg, bg),
        label,
        sub,
        Icon(Icons.chevron_right_rounded, color: _secondaryText),
        onTap: onTap,
      );
}
