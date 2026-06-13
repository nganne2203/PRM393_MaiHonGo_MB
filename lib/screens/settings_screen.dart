import 'package:flutter/material.dart';

import '../features/settings/repositories/app_preferences_repository.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class SettingsScreen extends StatefulWidget {
  final Future<void> Function() onLogout;
  final AppPreferencesRepository preferencesRepository;

  SettingsScreen({
    super.key,
    required this.onLogout,
    AppPreferencesRepository? preferencesRepository,
  }) : preferencesRepository =
            preferencesRepository ?? AppPreferencesRepository();

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettings _settings = const AppSettings.defaults();
  bool _loading = true;
  bool _saving = false;
  String? _message;

  bool get _dark => _settings.darkModeEnabled;
  bool get _notif => _settings.notificationsEnabled;
  bool get _audio => _settings.soundEffectsEnabled;

  Color get _background => _dark ? const Color(0xFF17182A) : AppColors.bg;
  Color get _surface => _dark ? const Color(0xFF23243A) : Colors.white;
  Color get _primaryText => _dark ? Colors.white : AppColors.ink;
  Color get _secondaryText =>
      _dark ? Colors.white.withValues(alpha: 0.68) : AppColors.mute;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
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
                  'Settings',
                  style: AppTextStyles.h2.copyWith(color: _primaryText),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading || _saving)
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
              'Dark Mode',
              _dark
                  ? 'Dark appearance is active here'
                  : 'Easy on the eyes at night',
              _dark,
              _setDarkMode,
            ),
            _toggleRow(
              Icons.notifications_outlined,
              AppColors.sakura,
              AppColors.sakuraSoft,
              'Notifications',
              _notif
                  ? 'Daily reminder at ${_settings.reminderLabel}'
                  : 'Daily reminders are off',
              _notif,
              _setNotifications,
            ),
            if (_notif)
              _navRow(
                Icons.schedule_rounded,
                AppColors.gold,
                AppColors.goldSoft,
                'Reminder Time',
                _settings.reminderLabel,
                onTap: _chooseReminderTime,
              ),
            _toggleRow(
              Icons.volume_up_outlined,
              AppColors.matcha,
              AppColors.matchaSoft,
              'Sound Effects',
              _audio ? 'Audio feedback in app' : 'Feedback sounds are muted',
              _audio,
              _setSoundEffects,
            ),
            const SizedBox(height: 16),
            _section('LEARNING'),
            _navRow(
              Icons.language_rounded,
              AppColors.sky,
              AppColors.skySoft,
              'App Language',
              _settings.languageLabel,
              onTap: _chooseLanguage,
            ),
            _navRow(
              Icons.track_changes_rounded,
              AppColors.matcha,
              AppColors.matchaSoft,
              'Weekly Goal',
              '${_settings.weeklyGoalDays} days per week',
              onTap: _chooseWeeklyGoal,
            ),
            _navRow(
              Icons.download_rounded,
              AppColors.primary,
              AppColors.primarySoft,
              'Offline Downloads',
              'Manage downloaded lessons',
              onTap: () => Navigator.pushNamed(context, '/offline-downloads'),
            ),
            const SizedBox(height: 16),
            _section('ACCOUNT'),
            _navRow(
              Icons.shield_outlined,
              AppColors.gold,
              AppColors.goldSoft,
              'Privacy & Security',
              'Password, profile, and local data',
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
                    const Text(
                      'Log Out',
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
        child: Text(s, style: AppTextStyles.overline),
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

  Future<void> _loadSettings() async {
    final settings = await widget.preferencesRepository.getSettings();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _save(
      Future<AppSettings> Function() action, String message) async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final settings = await action();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _message = message;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setDarkMode(bool value) {
    return _save(
      () => widget.preferencesRepository.setDarkModeEnabled(value),
      value ? 'Dark mode enabled.' : 'Dark mode disabled.',
    );
  }

  Future<void> _setNotifications(bool value) {
    return _save(
      () => widget.preferencesRepository.setNotificationsEnabled(value),
      value ? 'Study reminders enabled.' : 'Study reminders disabled.',
    );
  }

  Future<void> _setSoundEffects(bool value) {
    return _save(
      () => widget.preferencesRepository.setSoundEffectsEnabled(value),
      value ? 'Sound effects enabled.' : 'Sound effects muted.',
    );
  }

  Future<void> _setLanguageCode(String code) {
    return _save(
      () => widget.preferencesRepository.setLanguageCode(code),
      'Language preference updated.',
    );
  }

  Future<void> _setWeeklyGoalDays(int days) {
    return _save(
      () => widget.preferencesRepository.setWeeklyGoalDays(days),
      'Weekly goal updated.',
    );
  }

  Future<void> _setReminderMinutes(int minutes) {
    return _save(
      () => widget.preferencesRepository.setReminderMinutes(minutes),
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
            _choiceTile(context, 'en', 'English'),
            _choiceTile(context, 'vi', 'Vietnamese'),
            _choiceTile(context, 'ja', 'Japanese'),
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
            _goalTile(context, 3, 'Light pace'),
            _goalTile(context, 5, 'Steady pace'),
            _goalTile(context, 7, 'Daily practice'),
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
        title: const Text('Log out?'),
        content: const Text('You can sign back in with this account anytime.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
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
      title: Text('$days days per week', style: TextStyle(color: _primaryText)),
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
