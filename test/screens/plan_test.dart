import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_preccent/app/app_state.dart';
import 'package:one_preccent/main.dart';

import '../support/menu.dart';
import '../support/test_llm_client.dart';

void main() {
  testWidgets(
    'Plan lists five stages, marks the current one, and is view only',
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
      // Dummy session: go straight to the main app.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HabitAgentApp)),
      );
      container.read(appProvider.notifier).finishOnboarding();
      await tester.pump();

      await chooseInMenu(tester, 'Plan');
      await tester.pumpAndSettle();

      expect(find.text('You are here'), findsOneWidget);
      expect(find.text('Stage 1 name (placeholder)'), findsOneWidget);
      expect(find.text('Stage 5 name (placeholder)'), findsOneWidget);
      expect(find.textContaining('Your goal:'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
