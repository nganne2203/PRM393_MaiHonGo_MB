import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maihongo/widgets/flashcard.dart';

void main() {
  testWidgets('FlipFlashcard keeps identical phone dimensions for all content',
      (tester) async {
    await _setViewport(tester, const Size(400, 800));

    const words = ['水', '学校', '今日', '図書館', '国際交流センター'];
    Size? firstSize;

    for (final word in words) {
      await _pumpFlashcard(tester, word: word);

      final size = tester.getSize(find.byType(FlipFlashcard));
      firstSize ??= size;

      expect(size, firstSize);
      expect(size.width, 300);
      expect(size.height, 435);
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('FlipFlashcard uses fixed desktop dimensions', (tester) async {
    await _setViewport(tester, const Size(1200, 900));
    await _pumpFlashcard(
      tester,
      word: '国際交流センター',
      platform: TargetPlatform.macOS,
    );

    final size = tester.getSize(find.byType(FlipFlashcard));

    expect(size.width, FlashcardDimensions.desktopWidth);
    expect(size.height, FlashcardDimensions.desktopHeight);

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}

Future<void> _setViewport(WidgetTester tester, Size logicalSize) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = logicalSize;
}

Future<void> _pumpFlashcard(
  WidgetTester tester, {
  required String word,
  TargetPlatform platform = TargetPlatform.android,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: platform),
      home: Scaffold(
        body: Center(
          child: FlipFlashcard(
            kanji: word,
            kana: 'こくさいこうりゅうセンター',
            romaji: 'kokusai koryu senta',
            meaning: 'International exchange center',
            example: '国際交流センターに行きます。',
            exampleTr: 'I will go to the international exchange center.',
          ),
        ),
      ),
    ),
  );
}
