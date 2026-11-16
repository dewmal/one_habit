import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_preccent/app/app_state.dart';
import 'package:one_preccent/app/dummy_data.dart';
import 'package:one_preccent/app/day_state.dart';
import 'package:one_preccent/main.dart';

import '../support/menu.dart';
import '../support/test_llm_client.dart';

void main() {
  testWidgets(
    'History lists days newest first with plain summaries and no scores',
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
      container.read(dayProvider.notifier).startDay(dummyStepsFor('beginner'));
      container.read(dayProvider.notifier).toggleTask(0);
      container.read(appProvider.notifier).finishOnboarding();
      await tester.pumpAndSettle();

      await chooseInMenu(tester, 'History');

      expect(find.text('Your logs, newest first'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('1 done, 2 not logged yet'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('All 3 steps done'), findsOneWidget);
      expect(find.text('Rest day, nothing logged'), findsOneWidget);
      expect(find.text('All 3 steps skipped'), findsOneWidget);
      expect(find.textContaining('score'), findsNothing);
      expect(find.textContaining('streak', findRichText: true), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
