import 'package:flutter/material.dart';
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_tabs.length, (i) {
          final active = i == index;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: active ? 48 : 40, height: 36,
                  decoration: BoxDecoration(
                    gradient: active ? AppGradients.primary : null,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(_tabs[i].$1,
                      color: active ? Colors.white : AppColors.mute, size: 20),
                ),
                const SizedBox(height: 4),
                Text(_tabs[i].$2, style: TextStyle(
                  fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppColors.primary : AppColors.mute,
                )),
              ],
            ),
          );
        }),
      ),
    );
  }
}
