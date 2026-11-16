import 'dart:convert';

import 'package:one_preccent/plugins/habit_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_preccent/app/app_state.dart';
import 'package:one_preccent/app/day_state.dart';
import 'package:one_preccent/main.dart';
import 'package:one_preccent/plugins/fitness_plugin.dart';

import '../support/menu.dart';
import '../support/memory_database.dart';
import '../support/test_llm_client.dart';

void main() {
  testWidgets(
    'History lists days newest first with plain summaries and no scores',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: testAiOverrides(database: _withPastDays()),
          child: const HabitAgentApp(),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HabitAgentApp)),
      );
      container
          .read(dayProvider.notifier)
          .startDay(fitnessPlugin.fallbackStepsFor('beginner'));
      container.read(dayProvider.notifier).toggleTask(0);
      container.read(appProvider.notifier).finishOnboarding();
      await tester.pumpAndSettle();

      await chooseInMenu(tester, 'History');

      expect(find.text('Your logs, newest first'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('1 done, 2 not logged yet'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('All 3 steps done'), findsOneWidget);
      expect(find.text('Rest day, nothing logged'), findsOneWidget);
      expect(find.text('All 3 steps skipped'), findsOneWidget);
      expect(find.textContaining('score'), findsNothing);
      expect(find.textContaining('streak', findRichText: true), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

/// Five saved days before today, in the shape of the History design.
MemoryAppDatabase _withPastDays() {
  final db = seededDatabase();
  final today = DateTime.now();
  void day(int ago, Map<int, TaskResult> results, Feeling? feeling) {
    db.saveDay(
      1,
      date: dayKey(DateTime(today.year, today.month, today.day - ago)),
      results: jsonEncode({
        for (final e in results.entries) '${e.key}': e.value.name,
      }),
      feeling: feeling?.name,
    );
  }

  day(1, {
    0: TaskResult.done,
    1: TaskResult.done,
    2: TaskResult.done,
  }, Feeling.easy);
  day(2, {0: TaskResult.done}, Feeling.okay);
  day(3, {}, null);
  day(4, {
    0: TaskResult.skipped,
    1: TaskResult.skipped,
    2: TaskResult.skipped,
  }, Feeling.hard);
  day(5, {
    0: TaskResult.done,
    1: TaskResult.done,
    2: TaskResult.partly,
  }, Feeling.okay);
  return db;
}
