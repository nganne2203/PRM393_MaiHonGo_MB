import 'package:flutter/material.dart';
import '../core/localization/app_localizations.dart';
import '../theme/app_palette.dart';
import '../theme/tokens.dart';

class AppBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const AppBottomNav({super.key, required this.index, required this.onTap});

  static const _tabs = [
    (Icons.home_rounded, 'Home'),
    (Icons.school_rounded, 'Learn'),
    (Icons.bookmark_rounded, 'Saved'),
    (Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          color: context.colors.surface.withValues(alpha: 0.95),
          border: Border(top: BorderSide(color: context.colors.line)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_tabs.length, (i) {
            final active = i == index;
            return GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: active ? 48 : 40,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: active ? AppGradients.primary : null,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      _tabs[i].$1,
                      color: active ? Colors.white : context.colors.mute,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr(_tabs[i].$2),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? AppColors.primary : context.colors.mute,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
