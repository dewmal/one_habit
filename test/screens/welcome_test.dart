import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_preccent/main.dart';

void main() {
  testWidgets(
    'welcome shows the AI note without scrolling and Start leaves it',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const ProviderScope(child: HabitAgentApp()));

      expect(find.textContaining("I'm an AI coach"), findsOneWidget);
      expect(find.byType(Scrollable), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Start'));
      await tester.pump();
      expect(find.textContaining("I'm an AI coach"), findsNothing);
    },
  );

  testWidgets('welcome also fits a small phone (360 x 640)', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: HabitAgentApp()));
    expect(tester.takeException(), isNull);
  });
}
