import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';

class AppStatusBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final VoidCallback? onRetry;

  const AppStatusBanner({
    super.key,
    required this.icon,
    required this.message,
    required this.color,
    this.onRetry,
  });

  factory AppStatusBanner.offline({
    Key? key,
    required String message,
  }) =>
      AppStatusBanner(
        key: key,
        icon: Icons.cloud_off_rounded,
        message: message,
        color: AppColors.gold,
      );

  factory AppStatusBanner.error({
    Key? key,
    required String message,
    VoidCallback? onRetry,
  }) =>
      AppStatusBanner(
        key: key,
        icon: Icons.error_outline_rounded,
        message: message,
        color: AppColors.sakura,
        onRetry: onRetry,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class AppStatePlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryLabel;

  const AppStatePlaceholder({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.onRetry,
    this.retryLabel = 'Retry',
  });

  factory AppStatePlaceholder.empty({
    Key? key,
    IconData icon = Icons.inbox_outlined,
    required String title,
    String? message,
    VoidCallback? onRetry,
  }) =>
      AppStatePlaceholder(
        key: key,
        icon: icon,
        title: title,
        message: message,
        onRetry: onRetry,
      );

  factory AppStatePlaceholder.offline({
    Key? key,
    required String title,
    String? message,
    VoidCallback? onRetry,
  }) =>
      AppStatePlaceholder(
        key: key,
        icon: Icons.cloud_off_rounded,
        title: title,
        message: message,
        onRetry: onRetry,
      );

  factory AppStatePlaceholder.error({
    Key? key,
    required String title,
    String? message,
    VoidCallback? onRetry,
  }) =>
      AppStatePlaceholder(
        key: key,
        icon: Icons.error_outline_rounded,
        title: title,
        message: message,
        onRetry: onRetry,
      );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.mute, size: 26),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 4),
              Text(
                message!,
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onRetry, child: Text(retryLabel)),
            ],
          ],
        ),
      ),
    );
  }
}

class AppLoadingState extends StatelessWidget {
  final String? message;

  const AppLoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(message!, style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }
}
