import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world/main.dart';

void main() {
  testWidgets('Next button updates the displayed word pair', (
    WidgetTester tester,
  ) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the initial word pair is displayed.
    final initialWordPair = find.byType(BigCard);
    expect(initialWordPair, findsOneWidget);

    // Tap the "Next" button.
    final nextButton = find.widgetWithText(ElevatedButton, 'Next');
    expect(nextButton, findsOneWidget);
    await tester.tap(nextButton);

    // Trigger a frame to reflect the state change.
    await tester.pump();

    // Verify that the displayed word pair has changed.
    final updatedWordPair = find.byType(BigCard);
    expect(updatedWordPair, findsOneWidget);
    expect(updatedWordPair, isNot(initialWordPair));
  });
}
