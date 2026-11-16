import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_preccent/app/app_state.dart';
import 'package:one_preccent/app/day_state.dart';
import 'package:one_preccent/app/dummy_data.dart';
import 'package:one_preccent/chat/chat_controller.dart';
import 'package:one_preccent/main.dart';

import '../support/menu.dart';
import '../support/test_llm_client.dart';

void main() {
  testWidgets('after missed days the step gets smaller and never bigger', (
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

    await chooseInMenu(tester, 'General');
    container.read(chatProvider.notifier).openMissedDays();
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Missed days happen. Nothing is lost and your plan stays where it is.',
      ),
      findsOneWidget,
    );
    expect(find.text('Smaller'), findsOneWidget);
    expect(find.text('Was: 3 steps. Now: 1 step.'), findsOneWidget);
    expect(find.text(dummySmallestStep), findsOneWidget);

    await tester.tap(find.text('Still too much'));
    await tester.pumpAndSettle();
    expect(find.text(dummyTinierStep), findsOneWidget);
    expect(container.read(chatProvider).steps.length, 1);

    await tester.tap(find.text('Okay'));
    await tester.pumpAndSettle();
    expect(find.text('Good. See you tomorrow.'), findsOneWidget);
    // The card stays in the chat as the record of the smaller step.
    expect(find.text(dummyTinierStep), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
