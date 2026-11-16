import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_preccent/app/app_state.dart';
import 'package:one_preccent/app/day_state.dart';
import 'package:one_preccent/app/projects.dart';
import 'package:one_preccent/main.dart';

import '../support/memory_database.dart';
import '../support/menu.dart';
import '../support/test_llm_client.dart';

void main() {
  /// The seeded habit plus these habits, and an Exercise topic chat.
  MemoryAppDatabase database(List<String> more) {
    final db = seededDatabase();
    db.createChat(1, 'topic', 'Exercise');
    for (final name in more) {
      db
          .createHabit(pluginId: 'fitness', name: name)
          .then((id) => db.createChat(id, 'general', 'General'));
    }
    return db;
  }

  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    List<String> more = const [],
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: testAiOverrides(database: database(more)),
        child: const HabitAgentApp(),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HabitAgentApp)),
    );
    container.read(dayProvider.notifier).startDay([
      'Pack your gym bag tonight',
    ]);
    container.read(appProvider.notifier).finishOnboarding();
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('menu lists habits, chats and views; more habits expands', (
    tester,
  ) async {
    await pumpApp(
      tester,
      more: ['Read more', 'Drink water', 'Sleep earlier', 'Study daily'],
    );
    await openMenu(tester);

    expect(find.text('One habit'), findsOneWidget);
    expect(find.text('General'), findsOneWidget);
    expect(find.text('Exercise'), findsOneWidget);
    expect(find.text('Read more'), findsOneWidget);
    expect(find.text('Sleep earlier'), findsNothing);

    await tester.ensureVisible(find.text('Show 2 more habits'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show 2 more habits'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.descendant(of: find.byType(Drawer), matching: find.byType(ListView)),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sleep earlier'), findsOneWidget);
    expect(find.text('Show 2 more habits'), findsNothing);
    expect(find.text('Show fewer habits'), findsOneWidget);
  });

  testWidgets('tapping another habit makes it the current project', (
    tester,
  ) async {
    final container = await pumpApp(tester, more: ['Read more']);
    await chooseInMenu(tester, 'Read more');
    expect(container.read(projectsProvider).currentId, 2);
    expect(find.text('Read more · AI'), findsOneWidget);
  });

  testWidgets('New chat starts a topic chat that shares the habit', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    await chooseInMenu(tester, 'General');
    expect(find.text('Improve my fitness · AI'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('New chat'), findsOneWidget);
    expect(find.text('Start chat'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Sleep');
    await tester.tap(find.text('Start chat'));
    await tester.pumpAndSettle();

    final state = container.read(projectsProvider);
    expect(state.currentChat.title, 'Sleep');
    expect(state.currentChat.general, isFalse);
    expect(find.text('Sleep'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Thanks for telling me. Small steps.'), findsOneWidget);
  });
}
