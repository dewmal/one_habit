import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_preccent/app/app_state.dart';
import 'package:one_preccent/app/day_state.dart';
import 'package:one_preccent/app/dummy_data.dart';
import 'package:one_preccent/app/rules.dart';
import 'package:one_preccent/chat/chat_controller.dart';
import 'package:one_preccent/main.dart';

void main() {
  test('the hard stop words are detected in code', () {
    expect(isHardStop('I feel really low today'), isTrue);
    expect(isHardStop('I feel unwell'), isTrue);
    expect(isHardStop('Walk to the gym'), isFalse);
  });

  testWidgets('feeling low pauses everything and the user can resume', (
    tester,
  ) async {
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
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'I feel really low today');
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();

    expect(find.text('Everything is paused'), findsOneWidget);
    expect(find.text('Keep it paused'), findsOneWidget);
    expect(container.read(dayProvider).paused, isTrue);

    // Pushes stop while paused: a missed-day card is not offered.
    container.read(chatProvider.notifier).openMissedDays();
    await tester.pumpAndSettle();
    expect(find.text('Smaller'), findsNothing);

    await tester.tap(find.text("I'm okay to continue"));
    await tester.pumpAndSettle();
    expect(container.read(dayProvider).paused, isFalse);
    expect(find.text('Good. Tasks and reminders are back on.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
