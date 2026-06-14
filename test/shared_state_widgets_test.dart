import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maihongo/shared/widgets/app_state_widgets.dart';

void main() {
  testWidgets('AppLoadingState renders loading message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppLoadingState(message: 'Loading lessons...'),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading lessons...'), findsOneWidget);
  });

  testWidgets('AppStatusBanner renders error retry action', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppStatusBanner.error(
            message: 'Could not load data.',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Could not load data.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('AppStatePlaceholder renders empty and offline states',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AppStatePlaceholder.empty(title: 'No saved words yet.'),
              AppStatePlaceholder.offline(
                title: 'Lesson not available offline',
                message: 'Download it first.',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('No saved words yet.'), findsOneWidget);
    expect(find.text('Lesson not available offline'), findsOneWidget);
    expect(find.text('Download it first.'), findsOneWidget);
  });
}
