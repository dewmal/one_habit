import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_preccent/main.dart';

Future<void> _finishPlacement(WidgetTester tester) async {
  await tester.tap(find.text('Start'));
  await tester.pump();
  await tester.enterText(find.byType(TextField), 'Gym every day');
  await tester.tap(find.byIcon(Icons.arrow_forward));
  await tester.pump();
  await tester.tap(find.text('Most days'));
  await tester.pump();
  await tester.tap(find.text('15 minutes'));
  await tester.pump();
  await tester.tap(find.text('Evening'));
  await tester.pump();
  await tester.tap(find.text('No'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('health check asks 4 yes/no questions and returns to chat', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: HabitAgentApp()));
    await _finishPlacement(tester);

    expect(find.text('Quick health check'), findsOneWidget);
    expect(find.text('Question 1 of 4'), findsOneWidget);

    await tester.tap(find.text('No'));
    await tester.pump();
    expect(find.text('Question 2 of 4'), findsOneWidget);

    // Back returns to the previous question.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    expect(find.text('Question 1 of 4'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('No'));
      await tester.pump();
    }
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect(find.text('Quick health check'), findsNothing);
    expect(find.text('Thanks. Here is where we start.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
