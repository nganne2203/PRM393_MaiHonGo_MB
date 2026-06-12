import 'package:flutter/material.dart';
import '../features/settings/repositories/app_preferences_repository.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onLogout;
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

  bool get _dark => _settings.darkModeEnabled;
  bool get _notif => _settings.notificationsEnabled;
  bool get _audio => _settings.soundEffectsEnabled;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Row(
              children: [
                const BackButton(),
                Text('Settings', style: AppTextStyles.h2),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const LinearProgressIndicator(minHeight: 2)
            else
              const SizedBox(height: 2),
            const SizedBox(height: 14),
            _section('PREFERENCES'),
            _toggleRow(
              Icons.dark_mode_outlined,
              AppColors.primary,
              AppColors.primarySoft,
              'Dark Mode',
              'Easy on the eyes at night',
              _dark,
              _setDarkMode,
            ),
            _toggleRow(
              Icons.notifications_outlined,
              AppColors.sakura,
              AppColors.sakuraSoft,
              'Notifications',
              'Daily reminders to study',
              _notif,
              _setNotifications,
            ),
            _toggleRow(
              Icons.volume_up_outlined,
              AppColors.matcha,
              AppColors.matchaSoft,
              'Sound Effects',
              'Audio feedback in app',
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
              'English',
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
              'Manage your data',
              onTap: () => Navigator.pushNamed(context, '/change-password'),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: widget.onLogout,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.sakuraSoft),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: AppColors.sakura,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
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
            const Center(
              child: Text(
                'Sakura · v1.0.0',
                style: TextStyle(color: AppColors.mute, fontSize: 11),
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

  Future<void> _loadSettings() async {
    final settings = await widget.preferencesRepository.getSettings();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _setDarkMode(bool value) async {
    setState(() => _settings = _settings.copyWith(darkModeEnabled: value));
    final settings =
        await widget.preferencesRepository.setDarkModeEnabled(value);
    if (mounted) setState(() => _settings = settings);
  }

  Future<void> _setNotifications(bool value) async {
    setState(() => _settings = _settings.copyWith(notificationsEnabled: value));
    final settings =
        await widget.preferencesRepository.setNotificationsEnabled(value);
    if (mounted) setState(() => _settings = settings);
  }

  Future<void> _setSoundEffects(bool value) async {
    setState(() => _settings = _settings.copyWith(soundEffectsEnabled: value));
    final settings =
        await widget.preferencesRepository.setSoundEffectsEnabled(value);
    if (mounted) setState(() => _settings = settings);
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
        color: Colors.white,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub,
                    style: const TextStyle(
                      color: AppColors.mute,
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
    return GestureDetector(onTap: onTap, child: content);
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
          onChanged: onChange,
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
        const Icon(Icons.chevron_right_rounded, color: AppColors.mute),
        onTap: onTap,
      );
}
