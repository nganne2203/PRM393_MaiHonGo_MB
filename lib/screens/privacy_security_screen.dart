import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/models/auth_models.dart';
import '../features/auth/state/auth_state.dart';
import '../features/offline/state/offline_controller.dart';
import '../features/settings/repositories/app_preferences_repository.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class PrivacySecurityScreen extends ConsumerStatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  ConsumerState<PrivacySecurityScreen> createState() =>
      _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends ConsumerState<PrivacySecurityScreen> {
  final _preferencesRepository = AppPreferencesRepository();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final offlineState = ref.watch(offlineProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Row(
              children: [
                const BackButton(),
                Expanded(
                    child: Text('Privacy & Security', style: AppTextStyles.h2)),
              ],
            ),
            const SizedBox(height: 20),
            Text('ACCOUNT', style: AppTextStyles.overline),
            const SizedBox(height: 8),
            _accountCard(user),
            const SizedBox(height: 18),
            Text('SECURITY', style: AppTextStyles.overline),
            const SizedBox(height: 8),
            _actionRow(
              icon: Icons.lock_reset_rounded,
              fg: AppColors.primary,
              bg: AppColors.primarySoft,
              title: 'Change Password',
              subtitle: 'Update the password for this account',
              onTap: () => Navigator.pushNamed(context, '/change-password'),
            ),
            _actionRow(
              icon: Icons.verified_user_outlined,
              fg: AppColors.matcha,
              bg: AppColors.matchaSoft,
              title: 'Refresh Account',
              subtitle: 'Reload profile and session data',
              onTap: _busy ? null : _refreshAccount,
            ),
            const SizedBox(height: 18),
            Text('LOCAL DATA', style: AppTextStyles.overline),
            const SizedBox(height: 8),
            _actionRow(
              icon: Icons.download_done_rounded,
              fg: AppColors.sky,
              bg: AppColors.skySoft,
              title: 'Offline Downloads',
              subtitle:
                  '${offlineState.downloadedLessons.length} lessons stored on this device',
              onTap: () => Navigator.pushNamed(context, '/offline-downloads'),
            ),
            _actionRow(
              icon: Icons.cleaning_services_rounded,
              fg: AppColors.gold,
              bg: AppColors.goldSoft,
              title: 'Clear Offline Downloads',
              subtitle: 'Remove downloaded lessons from local storage',
              onTap: _busy ? null : _clearOfflineDownloads,
            ),
            _actionRow(
              icon: Icons.school_outlined,
              fg: AppColors.sakura,
              bg: AppColors.sakuraSoft,
              title: 'Show Onboarding Again',
              subtitle: 'Reset the tutorial for the next launch',
              onTap: _busy ? null : _resetOnboarding,
            ),
            const SizedBox(height: 20),
            if (_busy)
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _accountCard(UserModel? user) {
    final email = user?.email.isNotEmpty == true ? user!.email : 'Not loaded';
    final provider = user == null ? 'Unknown' : _providerLabel(user.provider);
    final verified = user?.emailVerified == true ? 'Verified' : 'Not verified';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primarySoft,
            child: Text(
              _initials(user?.name ?? user?.email ?? 'L'),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name.isNotEmpty == true ? user!.name : 'Learner',
                  style:
                      AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(email, style: AppTextStyles.caption),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _pill(provider, AppColors.primary, AppColors.primarySoft),
                    _pill(verified, AppColors.matcha, AppColors.matchaSoft),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required Color fg,
    required Color bg,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: fg, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.mute),
        ],
      ),
    );

    if (onTap == null) return Opacity(opacity: 0.6, child: content);
    return GestureDetector(onTap: onTap, child: content);
  }

  Widget _pill(String label, Color fg, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

  Future<void> _refreshAccount() async {
    await _runAction(() async {
      await ref.read(authControllerProvider.notifier).restoreSession();
      _showMessage('Account refreshed.');
    });
  }

  Future<void> _resetOnboarding() async {
    await _runAction(() async {
      await _preferencesRepository.setOnboardingCompleted(false);
      _showMessage('Onboarding will show again next time.');
    });
  }

  Future<void> _clearOfflineDownloads() async {
    final downloaded = ref.read(offlineProvider).downloadedLessons;
    if (downloaded.isEmpty) {
      _showMessage('There are no offline downloads to clear.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear downloads?'),
        content: Text(
          'This removes ${downloaded.length} downloaded lessons from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _runAction(() async {
      final controller = ref.read(offlineProvider.notifier);
      for (final item in downloaded) {
        await controller.removeDownloadedLesson(item.lesson.id);
      }
      _showMessage('Offline downloads cleared.');
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _providerLabel(String provider) {
    switch (provider) {
      case 'google':
        return 'Google';
      case 'both':
        return 'Email + Google';
      case 'local':
      default:
        return 'Email';
    }
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'L';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
