import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';

class SavedScreen extends StatelessWidget {
  final VoidCallback onReview;
  const SavedScreen({super.key, required this.onReview});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
        children: [
          Text('Saved Words', style: AppTextStyles.h1),
          const SizedBox(height: 4),
          Text('0 bookmarked vocabulary', style: AppTextStyles.caption),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search saved words...',
              hintStyle: AppTextStyles.caption,
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.mute, size: 18),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: const BorderSide(color: AppColors.line),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onReview,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppGradients.sakura,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                  child:
                      const Icon(Icons.play_arrow_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Review Mode',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      Text('Practice all your saved words',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              children: [
                const Icon(Icons.bookmark_border_rounded,
                    color: AppColors.mute, size: 24),
                const SizedBox(height: 8),
                Text('Saved words will appear here.',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
