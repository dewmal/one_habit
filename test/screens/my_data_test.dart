import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_preccent/app/app_state.dart';
import 'package:one_preccent/app/day_state.dart';
import 'package:one_preccent/app/dummy_data.dart';
import 'package:one_preccent/main.dart';
import 'package:one_preccent/screens/my_data_page.dart';

import '../support/menu.dart';
import '../support/test_llm_client.dart';

void main() {
  testWidgets(
    'delete really removes the daily log, and delete everything returns to Welcome',
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
      expect(container.read(dayProvider).history, isNotEmpty);

      await openMenu(tester);
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My data'));
      await tester.pumpAndSettle();

      final list = find.descendant(
        of: find.byType(MyDataPage),
        matching: find.byType(Scrollable),
      );

      // Delete the daily log: one confirm, then it is really removed.
      final logRow = find.byKey(const ValueKey('data-log'));
      await _scrollInto(
        tester,
        find.descendant(of: logRow, matching: find.text('Delete')),
        list,
      );
      await tester.tap(
        find.descendant(of: logRow, matching: find.text('Delete')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(container.read(dayProvider).history, isEmpty);

      // View shows a read-only list.
      await tester.drag(list, const Offset(0, -600));
      await tester.pumpAndSettle();
      final chatRow = find.byKey(const ValueKey('data-chat'));
      await _scrollInto(
        tester,
        find.descendant(of: chatRow, matching: find.text('View')),
        list,
      );
      await tester.tap(
        find.descendant(of: chatRow, matching: find.text('View')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Saved on this phone'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete everything'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(find.text('Start'), findsOneWidget);
      expect(container.read(appProvider).phase, AppPhase.welcome);
      expect(tester.takeException(), isNull);
    },
  );
}

/// Drags the list until [target] sits inside the list's visible area.
Future<void> _scrollInto(
  WidgetTester tester,
  Finder target,
  Finder list,
) async {
  for (var i = 0; i < 12; i++) {
    final box = tester.getRect(list);
    final rect = tester.getRect(target);
    if (rect.top >= box.top && rect.bottom <= box.bottom) return;
    await tester.drag(list, const Offset(0, -150));
    await tester.pumpAndSettle();
  }
}
