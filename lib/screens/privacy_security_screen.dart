import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/app_localizations.dart';
import '../features/auth/models/auth_models.dart';
import '../features/auth/state/auth_state.dart';
import '../features/offline/state/offline_controller.dart';
import '../features/settings/repositories/app_preferences_repository.dart';
import '../theme/app_palette.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Row(
              children: [
                const BackButton(),
                Expanded(
                  child: Text(
                    context.tr('Privacy & Security'),
                    style: context.h2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(context.tr('ACCOUNT'), style: context.overlineText),
            const SizedBox(height: 8),
            _accountCard(user),
            const SizedBox(height: 18),
            Text(context.tr('SECURITY'), style: context.overlineText),
            const SizedBox(height: 8),
            _actionRow(
              icon: Icons.lock_reset_rounded,
              fg: AppColors.primary,
              bg: AppColors.primarySoft,
              title: context.tr('Change Password'),
              subtitle: context.tr('Update the password for this account'),
              onTap: () => Navigator.pushNamed(context, '/change-password'),
            ),
            _actionRow(
              icon: Icons.verified_user_outlined,
              fg: AppColors.matcha,
              bg: AppColors.matchaSoft,
              title: context.tr('Refresh Account'),
              subtitle: context.tr('Reload profile and session data'),
              onTap: _busy ? null : _refreshAccount,
            ),
            const SizedBox(height: 18),
            Text(context.tr('LOCAL DATA'), style: context.overlineText),
            const SizedBox(height: 8),
            _actionRow(
              icon: Icons.download_done_rounded,
              fg: AppColors.sky,
              bg: AppColors.skySoft,
              title: context.tr('Offline Downloads'),
              subtitle: context.l10n.isVietnamese
                  ? '${offlineState.downloadedLessons.length} bài học trên thiết bị này'
                  : '${offlineState.downloadedLessons.length} lessons stored on this device',
              onTap: () => Navigator.pushNamed(context, '/offline-downloads'),
            ),
            _actionRow(
              icon: Icons.cleaning_services_rounded,
              fg: AppColors.gold,
              bg: AppColors.goldSoft,
              title: context.tr('Clear Offline Downloads'),
              subtitle:
                  context.tr('Remove downloaded lessons from local storage'),
              onTap: _busy ? null : _clearOfflineDownloads,
            ),
            _actionRow(
              icon: Icons.school_outlined,
              fg: AppColors.sakura,
              bg: AppColors.sakuraSoft,
              title: context.tr('Show Onboarding Again'),
              subtitle: context.tr('Reset the tutorial for the next launch'),
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
        color: context.colors.surface,
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
                  user?.name.isNotEmpty == true
                      ? user!.name
                      : context.tr('Learner'),
                  style: context.bodyText.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(email, style: context.captionText),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _pill(context.tr(provider), AppColors.primary,
                        AppColors.primarySoft),
                    _pill(context.tr(verified), AppColors.matcha,
                        AppColors.matchaSoft),
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
        color: context.colors.surface,
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
                  style: context.bodyText.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(subtitle, style: context.captionText),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: context.colors.mute),
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
    final message = context.tr('Account refreshed.');
    await _runAction(() async {
      await ref.read(authControllerProvider.notifier).restoreSession();
      _showMessage(message);
    });
  }

  Future<void> _resetOnboarding() async {
    final message = context.tr('Onboarding will show again next time.');
    await _runAction(() async {
      await _preferencesRepository.setOnboardingCompleted(false);
      _showMessage(message);
    });
  }

  Future<void> _clearOfflineDownloads() async {
    final clearedMessage = context.tr('Offline downloads cleared.');
    final downloaded = ref.read(offlineProvider).downloadedLessons;
    if (downloaded.isEmpty) {
      _showMessage(context.tr('There are no offline downloads to clear.'));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Clear downloads?')),
        content: Text(
          context.l10n.isVietnamese
              ? 'Thao tác này sẽ xóa ${downloaded.length} bài học đã tải khỏi thiết bị.'
              : 'This removes ${downloaded.length} downloaded lessons from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('Clear')),
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
      _showMessage(clearedMessage);
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
