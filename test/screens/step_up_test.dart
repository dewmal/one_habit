import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_preccent/app/app_state.dart';
import 'package:one_preccent/app/day_state.dart';
import 'package:one_preccent/app/dummy_data.dart';
import 'package:one_preccent/chat/chat_controller.dart';
import 'package:one_preccent/main.dart';

import '../support/test_llm_client.dart';

void main() {
  testWidgets('step-up changes nothing unless the user says yes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(overrides: testAiOverrides(), child: const HabitAgentApp()),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HabitAgentApp)),
    );
    container.read(dayProvider.notifier).startDay(dummyStepsFor('beginner'));
    container.read(appProvider.notifier).finishOnboarding();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    container.read(chatProvider.notifier).openStepUp();
    await tester.pumpAndSettle();
    expect(find.text('Ready for a bit more?'), findsOneWidget);
    expect(find.text('Now: Stay for 5 minutes'), findsOneWidget);
    expect(find.text('A bit more: Stay for 10 minutes'), findsOneWidget);
    expect(find.text('Nothing changes unless you say yes.'), findsOneWidget);

    await tester.tap(find.text('Not yet'));
    await tester.pumpAndSettle();
    expect(find.text('No problem. Nothing changed.'), findsOneWidget);
    expect(container.read(chatProvider).steps, isEmpty);

    container.read(chatProvider.notifier).openStepUp();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(find.text('Done. The bigger step starts tomorrow.'), findsOneWidget);
    expect(container.read(chatProvider).steps, [dummyBiggerStep]);
    expect(tester.takeException(), isNull);
  });
}
