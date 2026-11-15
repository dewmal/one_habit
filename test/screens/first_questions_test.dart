import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_preccent/main.dart';

import '../support/test_llm_client.dart';

void main() {
  testWidgets('goal, then questions counted out of 5, then health check', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(overrides: testAiOverrides(), child: const HabitAgentApp()),
    );
    await tester.tap(find.text('Start'));
    await tester.pump();

    expect(
      find.text('Hi! What habit would you like to build?'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byType(TextField),
      'I want to go to the gym every day',
    );
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pump();

    expect(find.text('Question 2 of 5'), findsOneWidget);
    expect(find.text('How often do you exercise now?'), findsOneWidget);

    await tester.tap(find.text('Most days'));
    await tester.pump();
    expect(find.text('Question 3 of 5'), findsOneWidget);

    await tester.tap(find.text('15 minutes'));
    await tester.pump();
    await tester.tap(find.text('Evening'));
    await tester.pump();
    await tester.tap(find.text('No'));
    await tester.pump();
    expect(find.text('Thanks. Next, a quick health check.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
