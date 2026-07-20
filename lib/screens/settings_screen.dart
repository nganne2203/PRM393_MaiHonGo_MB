import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../core/localization/app_localizations.dart';
import '../core/sync/sync_manager.dart';
import '../features/settings/repositories/app_preferences_repository.dart';
import '../features/settings/state/app_settings_controller.dart';
import '../theme/app_theme.dart';
import '../theme/app_palette.dart';
import '../theme/tokens.dart';

const _reminderPresets = [
  _ReminderPreset(7 * 60 + 30, 'Morning study', Icons.wb_sunny_outlined),
  _ReminderPreset(12 * 60 + 15, 'Lunch review', Icons.lunch_dining_outlined),
  _ReminderPreset(20 * 60, 'Evening review', Icons.nights_stay_outlined),
  _ReminderPreset(21 * 60 + 30, 'Night recap', Icons.bedtime_outlined),
];

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
              _notificationSummary,
              _notif,
              _setNotifications,
              onTap: _chooseNotificationSettings,
            ),
            if (_notif)
              _navRow(
                Icons.schedule_rounded,
                AppColors.gold,
                AppColors.goldSoft,
                context.tr('Reminder Time'),
                _reminderSummary,
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
              onTap: _chooseSoundEffects,
            ),
            if (_audio)
              _navRow(
                Icons.graphic_eq_rounded,
                AppColors.matcha,
                AppColors.matchaSoft,
                context.tr('Sound Style'),
                _soundSummary,
                onTap: _chooseSoundEffects,
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
              _weeklyGoalSummary,
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
            _navRow(
              Icons.history_rounded,
              AppColors.gold,
              AppColors.goldSoft,
              context.tr('Practice History'),
              context.tr('Review quiz and practice results'),
              onTap: _choosePracticeHistory,
            ),
            _navRow(
              Icons.sync_rounded,
              AppColors.matcha,
              AppColors.matchaSoft,
              context.tr('Sync now'),
              context.tr('Upload pending learning activity'),
              onTap: _saving ? null : _syncNow,
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

  Future<void> _choosePracticeHistory() async {
    final route = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _surface,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.quiz_outlined),
              title: Text(context.tr('Quiz History')),
              onTap: () => Navigator.pop(sheetContext, '/quiz-history'),
            ),
            ListTile(
              leading: const Icon(Icons.headphones_rounded),
              title: Text(context.tr('Listening History')),
              onTap: () => Navigator.pop(sheetContext, '/listening-history'),
            ),
            ListTile(
              leading: const Icon(Icons.mic_none_rounded),
              title: Text(context.tr('Speaking History')),
              onTap: () => Navigator.pop(sheetContext, '/speaking-history'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note_rounded),
              title: Text(context.tr('Writing History')),
              onTap: () => Navigator.pop(sheetContext, '/writing-history'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || route == null) return;
    await Navigator.pushNamed(context, route);
  }

  Future<void> _syncNow() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final manager = await ref.read(syncManagerProvider.future);
      final report = await manager.synchronize();
      if (!mounted) return;
      setState(() {
        _message = report.succeeded
            ? context.l10n.isVietnamese
                ? 'Đồng bộ hoàn tất: ${report.syncedItems} mục.'
                : 'Sync complete: ${report.syncedItems} items.'
            : context.l10n.isVietnamese
                ? 'Một số dữ liệu chưa thể đồng bộ. Ứng dụng sẽ tự thử lại.'
                : 'Some data could not sync. The app will retry automatically.';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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

  String get _notificationSummary {
    if (!_notif) return context.tr('Daily reminders are off');
    return '${context.tr(_settings.notificationPlanLabel)} · ${context.tr('Daily reminder at')} ${_settings.reminderLabel}';
  }

  String get _reminderSummary {
    return '${_settings.reminderLabel} · ${_timeOfDayLabel(_settings.reminderMinutes)}';
  }

  String get _soundSummary {
    return '${context.tr(_settings.soundEffectPackLabel)} · ${_settings.soundEffectVolume}%';
  }

  String get _weeklyGoalSummary {
    if (context.l10n.isVietnamese) {
      return '${_settings.weeklyGoalDays} ngày/tuần · ${_settings.dailyWordGoal} từ/ngày · ${_settings.dailyStudyMinutes} phút';
    }
    return '${_settings.weeklyGoalDays} days/week · ${_settings.dailyWordGoal} words/day · ${_settings.dailyStudyMinutes} min';
  }

  String _timeOfDayLabel(int minutes) {
    final hour = minutes ~/ 60;
    if (hour >= 5 && hour < 11) return context.tr('Morning');
    if (hour >= 11 && hour < 15) return context.tr('Afternoon');
    if (hour >= 15 && hour < 20) return context.tr('Evening');
    return context.tr('Night');
  }

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

  Future<void> _setNotificationPlan(String plan) {
    return _save(
      () => ref
          .read(appSettingsControllerProvider.notifier)
          .setNotificationPlan(plan),
      'Notification schedule updated.',
    );
  }

  Future<void> _setSoundEffectPack(String pack) {
    return _save(
      () => ref
          .read(appSettingsControllerProvider.notifier)
          .setSoundEffectPack(pack),
      'Sound style updated.',
    );
  }

  Future<void> _setSoundEffectVolume(int volume) {
    return _save(
      () => ref
          .read(appSettingsControllerProvider.notifier)
          .setSoundEffectVolume(volume),
      'Sound volume updated.',
    );
  }

  Future<void> _setDailyWordGoal(int words) {
    return _save(
      () => ref
          .read(appSettingsControllerProvider.notifier)
          .setDailyWordGoal(words),
      'Weekly goal updated.',
    );
  }

  Future<void> _setDailyStudyMinutes(int minutes) {
    return _save(
      () => ref
          .read(appSettingsControllerProvider.notifier)
          .setDailyStudyMinutes(minutes),
      'Weekly goal updated.',
    );
  }

  Future<void> _chooseNotificationSettings() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _surface,
      showDragHandle: true,
      builder: (context) => _settingsSheet(
        title: context.tr('Study Notifications'),
        subtitle: context.tr('Choose when Sakura should nudge you to study.'),
        children: [
          _optionTile(
            context,
            value: 'daily',
            selected: _settings.notificationPlan,
            title: context.tr('Every day'),
            subtitle: context.tr('A steady reminder at your chosen time.'),
            icon: Icons.calendar_month_rounded,
          ),
          _optionTile(
            context,
            value: 'weekdays',
            selected: _settings.notificationPlan,
            title: context.tr('Weekdays only'),
            subtitle: context.tr('Study reminders from Monday to Friday.'),
            icon: Icons.work_outline_rounded,
          ),
        ],
      ),
    );
    if (selected == null || selected == _settings.notificationPlan) return;
    await _setNotificationPlan(selected);
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
      builder: (context) => _settingsSheet(
        title: context.tr('Weekly Goal'),
        subtitle: context.tr('Tune the amount of practice you want each week.'),
        children: [
          _goalTile(context, 3, context.tr('Light pace')),
          _goalTile(context, 5, context.tr('Steady pace')),
          _goalTile(context, 7, context.tr('Daily practice')),
          const SizedBox(height: 12),
          _stepperTile(
            context,
            title: context.tr('Words per day'),
            value: _settings.dailyWordGoal,
            min: 1,
            max: 50,
            step: 5,
            suffix: context.tr('words'),
            onChanged: (value) {
              Navigator.pop(context);
              _setDailyWordGoal(value);
            },
          ),
          _stepperTile(
            context,
            title: context.tr('Study minutes'),
            value: _settings.dailyStudyMinutes,
            min: 5,
            max: 120,
            step: 5,
            suffix: context.tr('min'),
            onChanged: (value) {
              Navigator.pop(context);
              _setDailyStudyMinutes(value);
            },
          ),
        ],
      ),
    );
    if (selected == null || selected == _settings.weeklyGoalDays) return;
    await _setWeeklyGoalDays(selected);
  }

  Future<void> _chooseReminderTime() async {
    const customValue = -1;
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: _surface,
      showDragHandle: true,
      builder: (context) => _settingsSheet(
        title: context.tr('Reminder Time'),
        subtitle: context.tr('Pick a time that fits your study rhythm.'),
        children: [
          for (final preset in _reminderPresets)
            _optionTile(
              context,
              value: preset.minutes,
              selected: _settings.reminderMinutes,
              title: preset.label(context),
              subtitle: preset.timeLabel,
              icon: preset.icon,
            ),
          _optionTile(
            context,
            value: customValue,
            selected: customValue,
            title: context.tr('Custom time'),
            subtitle: context.tr('Use the system time picker'),
            icon: Icons.more_time_rounded,
          ),
        ],
      ),
    );
    if (selected == null) return;
    if (selected == customValue) {
      final initial = TimeOfDay(
        hour: _settings.reminderMinutes ~/ 60,
        minute: _settings.reminderMinutes % 60,
      );
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: initial,
      );
      if (time == null) return;
      await _setReminderMinutes(time.hour * 60 + time.minute);
      return;
    }
    if (selected == _settings.reminderMinutes) return;
    await _setReminderMinutes(selected);
  }

  Future<void> _chooseSoundEffects() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _surface,
      showDragHandle: true,
      builder: (context) => _settingsSheet(
        title: context.tr('Sound Effects'),
        subtitle: context.tr('Choose the feedback style and volume.'),
        children: [
          _optionTile(
            context,
            value: 'sakura',
            selected: _settings.soundEffectPack,
            title: context.tr('Sakura pop'),
            subtitle:
                context.tr('Bright taps for correct answers and rewards.'),
            icon: Icons.auto_awesome_rounded,
          ),
          _optionTile(
            context,
            value: 'minimal',
            selected: _settings.soundEffectPack,
            title: context.tr('Minimal'),
            subtitle: context.tr('Short, quiet feedback for focused sessions.'),
            icon: Icons.volume_down_outlined,
          ),
          _optionTile(
            context,
            value: 'focus',
            selected: _settings.soundEffectPack,
            title: context.tr('Focus'),
            subtitle: context.tr('Softer cues for night study.'),
            icon: Icons.nightlight_round,
          ),
          const SizedBox(height: 12),
          _stepperTile(
            context,
            title: context.tr('Effect volume'),
            value: _settings.soundEffectVolume,
            min: 0,
            max: 100,
            step: 10,
            suffix: '%',
            onChanged: (value) {
              Navigator.pop(context);
              _setSoundEffectVolume(value);
            },
          ),
          TextButton.icon(
            onPressed: () => SystemSound.play(SystemSoundType.click),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(context.tr('Preview sound')),
          ),
        ],
      ),
    );
    if (selected == null || selected == _settings.soundEffectPack) return;
    await _setSoundEffectPack(selected);
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

  Widget _settingsSheet({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Text(title, style: context.h3),
          const SizedBox(height: 4),
          Text(subtitle, style: context.captionText),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _optionTile<T>(
    BuildContext context, {
    required T value,
    required T selected,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final active = value == selected;
    return GestureDetector(
      onTap: () => Navigator.pop(context, value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              active ? AppColors.primary.withValues(alpha: 0.12) : _background,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: active ? AppColors.primary : context.colors.line,
          ),
        ),
        child: Row(
          children: [
            _icon(icon, active ? AppColors.primary : AppColors.sky,
                active ? AppColors.primarySoft : AppColors.skySoft),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: context.bodyText
                          .copyWith(fontWeight: FontWeight.w800)),
                  Text(subtitle, style: context.captionText),
                ],
              ),
            ),
            if (active)
              const Icon(Icons.check_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _stepperTile(
    BuildContext context, {
    required String title,
    required int value,
    required int min,
    required int max,
    required int step,
    required String suffix,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        context.bodyText.copyWith(fontWeight: FontWeight.w800)),
                Text('$value $suffix', style: context.captionText),
              ],
            ),
          ),
          IconButton(
            onPressed: value <= min ? null : () => onChanged(value - step),
            icon: const Icon(Icons.remove_rounded),
          ),
          IconButton(
            onPressed: value >= max ? null : () => onChanged(value + step),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
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
    ValueChanged<bool> onChange, {
    VoidCallback? onTap,
  }) =>
      _row(
        _icon(icon, fg, bg),
        label,
        sub,
        Switch(
          value: value,
          onChanged: _saving ? null : onChange,
          activeThumbColor: AppColors.primary,
        ),
        onTap: onTap,
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

class _ReminderPreset {
  final int minutes;
  final String title;
  final IconData icon;

  const _ReminderPreset(this.minutes, this.title, this.icon);

  String label(BuildContext context) => context.tr(title);

  String get timeLabel {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
