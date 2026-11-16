import 'package:one_preccent/plugins/habit_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_preccent/app/app_state.dart';
import 'package:one_preccent/app/day_state.dart';
import 'package:one_preccent/main.dart';
import 'package:one_preccent/plugins/fitness_plugin.dart';

import '../support/test_llm_client.dart';

void main() {
  testWidgets(
    'log card needs every task and a feeling, then saves with the fixed reply',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: testAiOverrides(),
          child: const HabitAgentApp(),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HabitAgentApp)),
      );
      container
          .read(dayProvider.notifier)
          .startDay(fitnessPlugin.fallbackStepsFor('beginner'));
      container.read(appProvider.notifier).finishOnboarding();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log how it went'));
      await tester.pumpAndSettle();
      expect(find.text('How did today go?'), findsOneWidget);

      final save = find.widgetWithText(FilledButton, 'Save');
      expect(tester.widget<FilledButton>(save).onPressed, isNull);

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Partly').at(i));
        await tester.pump();
      }
      await tester.tap(find.text('Okay'));
      await tester.pump();
      expect(tester.widget<FilledButton>(save).onPressed, isNotNull);

      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsNothing);
      expect(
        find.text('Thanks for logging today. Every day you show up counts.'),
        findsOneWidget,
      );
      expect(container.read(dayProvider).history.first.feeling, Feeling.okay);
      expect(tester.takeException(), isNull);
    },
  );
}
