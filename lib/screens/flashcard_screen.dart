import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/flashcard.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  static const _cards = [
    {'kanji': '猫', 'kana': 'ねこ', 'romaji': 'neko', 'm': 'Mèo', 'ex': '猫が好きです。', 'exTr': 'Tôi thích mèo.'},
    {'kanji': '水', 'kana': 'みず', 'romaji': 'mizu', 'm': 'Nước', 'ex': '水を飲みます。', 'exTr': 'Tôi uống nước.'},
    {'kanji': '本', 'kana': 'ほん', 'romaji': 'hon', 'm': 'Sách', 'ex': '本を読む。', 'exTr': 'Đọc sách.'},
  ];
  int _i = 0;
  bool _saved = false;

  void _next(bool _) => setState(() {
    _i = (_i + 1) % _cards.length;
    _saved = false;
  });

  @override
  Widget build(BuildContext context) {
    final c = _cards[_i];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Row(children: [
            const BackButton(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (_i + 1) / _cards.length,
                      minHeight: 8,
                      backgroundColor: AppColors.line,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${_i + 1} / ${_cards.length}',
                      style: const TextStyle(color: AppColors.mute, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _saved = !_saved),
              icon: Icon(_saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: _saved ? AppColors.sakura : AppColors.mute),
            ),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: GestureDetector(
                onHorizontalDragEnd: (d) {
                  if (d.primaryVelocity == null) return;
                  _next(d.primaryVelocity! > 0);
                },
                child: FlipFlashcard(
                  kanji: c['kanji']!, kana: c['kana']!, romaji: c['romaji']!,
                  meaning: c['m']!, example: c['ex']!, exampleTr: c['exTr']!,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ctrlBtn(Icons.close_rounded, AppColors.sakura, AppColors.sakuraSoft, () => _next(false)),
              const SizedBox(width: 16),
              _ctrlBtn(Icons.refresh_rounded, AppColors.primary, AppColors.primarySoft, () {}),
              const SizedBox(width: 16),
              _ctrlBtn(Icons.check_rounded, Colors.white, AppColors.matcha, () => _next(true), filled: true),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _ctrlBtn(IconData icon, Color color, Color bg, VoidCallback onTap, {bool filled = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: filled ? 64 : 56, height: filled ? 64 : 56,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: filled ? AppShadows.button : null,
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}
