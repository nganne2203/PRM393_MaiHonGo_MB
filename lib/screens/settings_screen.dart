import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const SettingsScreen({super.key, required this.onLogout});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _dark = false, _notif = true, _audio = true;

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
            _section('PREFERENCES'),
            _toggleRow(
              Icons.dark_mode_outlined,
              AppColors.primary,
              AppColors.primarySoft,
              'Dark Mode',
              'Easy on the eyes at night',
              _dark,
              (v) => setState(() => _dark = v),
            ),
            _toggleRow(
              Icons.notifications_outlined,
              AppColors.sakura,
              AppColors.sakuraSoft,
              'Notifications',
              'Daily reminders to study',
              _notif,
              (v) => setState(() => _notif = v),
            ),
            _toggleRow(
              Icons.volume_up_outlined,
              AppColors.matcha,
              AppColors.matchaSoft,
              'Sound Effects',
              'Audio feedback in app',
              _audio,
              (v) => setState(() => _audio = v),
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
            ),
            const SizedBox(height: 16),
            _section('ACCOUNT'),
            _navRow(
              Icons.shield_outlined,
              AppColors.gold,
              AppColors.goldSoft,
              'Privacy & Security',
              'Manage your data',
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

  Widget _row(
    Widget leading,
    String label,
    String? sub,
    Widget trailing,
  ) =>
      Container(
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
    String sub,
  ) =>
      _row(
        _icon(icon, fg, bg),
        label,
        sub,
        const Icon(Icons.chevron_right_rounded, color: AppColors.mute),
      );
}
