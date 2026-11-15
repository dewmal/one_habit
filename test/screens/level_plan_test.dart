import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_preccent/main.dart';

import '../support/test_llm_client.dart';

Future<void> _toLevelCard(
  WidgetTester tester, {
  required String exercise,
  required List<bool> health,
}) async {
  await tester.pumpWidget(
    ProviderScope(overrides: testAiOverrides(), child: const HabitAgentApp()),
  );
  await tester.tap(find.text('Start'));
  await tester.pump();
  await tester.enterText(find.byType(TextField), 'Gym every day');
  await tester.tap(find.byIcon(Icons.arrow_forward));
  await tester.pump();
  await tester.tap(find.text(exercise));
  await tester.pump();
  await tester.tap(find.text('15 minutes'));
  await tester.pump();
  await tester.tap(find.text('Evening'));
  await tester.pump();
  await tester.tap(find.text('No'));
  await tester.pumpAndSettle();
  for (final yes in health) {
    await tester.tap(find.text(yes ? 'Yes' : 'No'));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'a Ready answer starts near the real habit, with Looks good and Make it smaller',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await _toLevelCard(
        tester,
        exercise: 'Most days',
        health: [false, false, false, false],
      );

      expect(find.text('Your starting level'), findsOneWidget);
      expect(find.text('Go to the gym'), findsOneWidget);
      expect(find.textContaining('Please see a doctor'), findsNothing);

      await tester.tap(find.text('Make it smaller'));
      await tester.pumpAndSettle();
      expect(find.text('Okay, I will make the steps smaller.'), findsOneWidget);
      expect(find.text('Go to the gym'), findsOneWidget);
      expect(find.text('Do 15 minutes of work'), findsNothing);
    },
  );

  testWidgets(
    'any Yes in the health check forces beginner and shows the doctor note',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await _toLevelCard(
        tester,
        exercise: 'Most days',
        health: [false, true, false, false],
      );

      expect(find.text('Pack your gym bag tonight'), findsOneWidget);
      expect(find.textContaining('Please see a doctor'), findsOneWidget);
      expect(find.text('Go to the gym'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
