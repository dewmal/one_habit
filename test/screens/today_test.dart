import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_preccent/app/day_state.dart';
import 'package:one_preccent/main.dart';

void main() {
  testWidgets(
    'Looks good opens Today with only today\'s tasks and the bottom nav',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const ProviderScope(child: HabitAgentApp()));
      await tester.tap(find.text('Start'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Gym every day');
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump();
      await tester.tap(find.text('Once or twice a week'));
      await tester.pump();
      await tester.tap(find.text('5 minutes'));
      await tester.pump();
      await tester.tap(find.text('Morning'));
      await tester.pump();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('No'));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      await tester.tap(find.text('Looks good'));
      await tester.pumpAndSettle();

      expect(find.text('Stage 1 of 5'), findsOneWidget);
      expect(find.text('Walk to the gym door'), findsOneWidget);
      expect(find.text('Log how it went'), findsOneWidget);
      expect(find.text('Streak'), findsNothing);
      expect(find.text('Chat'), findsOneWidget);

      await tester.tap(find.text('Walk to the gym door'));
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HabitAgentApp)),
      );
      expect(container.read(dayProvider).results[1], TaskResult.done);

      await tester.tap(find.text('Log how it went'));
      await tester.pumpAndSettle();
      expect(find.text('General'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
