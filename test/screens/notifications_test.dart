import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_preccent/app/app_state.dart';
import 'package:one_preccent/app/day_state.dart';
import 'package:one_preccent/app/dummy_data.dart';
import 'package:one_preccent/main.dart';
import 'package:one_preccent/screens/notifications_page.dart';

void main() {
  testWidgets(
    'notification buttons write to the daily log without opening the app',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const ProviderScope(child: HabitAgentApp()));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HabitAgentApp)),
      );
      container.read(dayProvider.notifier).startDay(dummyStepsFor('beginner'));
      container.read(appProvider.notifier).finishOnboarding();
      await tester.pumpAndSettle();

        Navigator.of(tester.element(find.byType(Scaffold).first))
          .push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
      await tester.pumpAndSettle();

      expect(find.text("Today's small step"), findsOneWidget);
      expect(
        find.text('Pack your gym bag tonight. That is all for now.'),
        findsOneWidget,
      );
      expect(
        find.text('Tap to log it. It takes a few seconds.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Done').first);
      await tester.pumpAndSettle();
      expect(container.read(dayProvider).results[0], TaskResult.done);
      expect(find.text("Today's small step"), findsNothing);

      await tester.tap(find.text('Too hard'));
      await tester.pumpAndSettle();
      expect(container.read(dayProvider).results[0], TaskResult.skipped);
      expect(tester.takeException(), isNull);
    },
  );
}
