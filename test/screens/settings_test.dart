import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_preccent/app/app_state.dart';
import 'package:one_preccent/app/day_state.dart';
import 'package:one_preccent/app/dummy_data.dart';
import 'package:one_preccent/app/settings_state.dart';
import 'package:one_preccent/main.dart';

import '../support/menu.dart';
import '../support/test_llm_client.dart';

void main() {
  testWidgets(
    'settings change at once: daily limit stays within 1 to 5 and time picker opens',
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
      container.read(appProvider.notifier).finishOnboarding();
      await tester.pumpAndSettle();

      await openMenu(tester);
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      expect(find.text('Most reminders a day'), findsOneWidget);
      expect(find.text('7:00 AM'), findsOneWidget);
      expect(find.text('9:00 PM to 7:00 AM'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(container.read(settingsProvider).dailyLimit, 3);

      for (var i = 0; i < 10; i++) {
        await tester.tap(find.byIcon(Icons.remove));
        await tester.pump();
      }
      expect(container.read(settingsProvider).dailyLimit, minDailyLimit);

      await tester.tap(find.text('Morning reminder'));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
