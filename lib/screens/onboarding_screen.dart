import 'package:flutter/material.dart';
import '../core/localization/app_localizations.dart';
import '../theme/app_palette.dart';
import '../theme/tokens.dart';
import '../widgets/primary_button.dart';

class _Slide {
  final String emoji, title, desc;
  final Gradient bg;
  const _Slide(this.emoji, this.title, this.desc, this.bg);
}

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _i = 0;

  static const _slides = [
    _Slide(
        '🎴',
        'Learn with Flashcards',
        'Master Kanji, Hiragana and Katakana with beautifully crafted flashcards.',
        AppGradients.sakura),
    _Slide(
        '🧠',
        'Practice with Quizzes',
        'Test what you know with smart quizzes that adapt to your level.',
        AppGradients.sky),
    _Slide(
        '🏆',
        'Track Your Progress',
        'Earn XP, build streaks and watch your Japanese skills bloom.',
        AppGradients.matcha),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onDone,
                child: Text(context.tr('Skip'),
                    style: context.captionText
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _i = i),
                itemBuilder: (_, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 256,
                          height: 256,
                          decoration: BoxDecoration(
                            gradient: s.bg,
                            borderRadius: BorderRadius.circular(48),
                            boxShadow: AppShadows.elevated,
                          ),
                          alignment: Alignment.center,
                          child: Text(s.emoji,
                              style: const TextStyle(fontSize: 110)),
                        ),
                        const SizedBox(height: 40),
                        Text(context.tr(s.title),
                            style: context.h1, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Text(context.tr(s.desc),
                            style: context.bodyText.copyWith(
                                color: context.colors.mute, height: 1.6),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  _slides.length,
                  (idx) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: idx == _i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: idx == _i
                              ? AppColors.primary
                              : context.colors.line,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      )),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: PrimaryButton(
                label: _i == _slides.length - 1
                    ? context.tr('Get Started')
                    : context.tr('Next'),
                trailingIcon: Icons.arrow_forward_rounded,
                onTap: () {
                  if (_i == _slides.length - 1) {
                    widget.onDone();
                  } else {
                    _ctrl.nextPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
