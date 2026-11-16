import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database_provider.dart';
import '../data/startup.dart';
import 'projects.dart';

enum TaskResult { done, partly, skipped }

enum Feeling { easy, okay, hard }

/// One saved day. A day with no results is a rest day.
class DayEntry {
  const DayEntry({required this.date, this.results = const {}, this.feeling});

  final DateTime date;

  /// Task index -> result.
  final Map<int, TaskResult> results;
  final Feeling? feeling;
}

class DayState {
  const DayState({
    this.tasks = const [],
    this.results = const {},
    this.history = const [],
    this.stageIndex = 0,
    this.offline = false,
    this.paused = false,
  });

  /// Today's small tasks, in order.
  final List<String> tasks;

  /// Today's log so far: task index -> result. Ticks write here, no AI call.
  final Map<int, TaskResult> results;

  /// Past days, newest first.
  final List<DayEntry> history;

  /// 0-based stage index. Shown as "Stage 1 of 5".
  final int stageIndex;

  final bool offline;
  final bool paused;

  DayState copyWith({
    List<String>? tasks,
    Map<int, TaskResult>? results,
    List<DayEntry>? history,
    int? stageIndex,
    bool? offline,
    bool? paused,
  }) => DayState(
    tasks: tasks ?? this.tasks,
    results: results ?? this.results,
    history: history ?? this.history,
    stageIndex: stageIndex ?? this.stageIndex,
    offline: offline ?? this.offline,
    paused: paused ?? this.paused,
  );
}

/// "2026-11-16", the key of a day in the daily_log table.
String dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

Map<int, TaskResult> _decodeResults(String json) => {
  for (final e in (jsonDecode(json) as Map<String, dynamic>).entries)
    int.parse(e.key): TaskResult.values.byName(e.value as String),
};

String _encodeResults(Map<int, TaskResult> results) =>
    jsonEncode({for (final e in results.entries) '${e.key}': e.value.name});

/// Today's plan and log. Every change is written to the plan and daily_log
/// tables, and read back when the app opens.
class DayController extends Notifier<DayState> {
  @override
  DayState build() {
    final start = ref.watch(startupProvider);
    if (start.habits.isEmpty) return const DayState();
    final today = dayKey(DateTime.now());
    final history = <DayEntry>[];
    var results = <int, TaskResult>{};
    for (final row in start.logs) {
      final date = DateTime.parse(row['log_date'] as String);
      final entry = DayEntry(
        date: date,
        results: _decodeResults(row['results'] as String),
        feeling: _feelingOf(row['feeling'] as String?),
      );
      if (row['log_date'] == today) results = entry.results;
      // Today shows live ticks until the log card is saved.
      if (row['log_date'] != today || entry.feeling != null) {
        history.add(entry);
      }
    }
    final plan = start.plan;
    return DayState(
      tasks: plan == null
          ? const []
          : List<String>.from(jsonDecode(plan['tasks'] as String) as List),
      stageIndex: (plan?['stage_index'] as int?) ?? 0,
      results: results,
      history: history,
      paused: start.habits.first['paused'] == 1,
    );
  }

  Feeling? _feelingOf(String? name) =>
      name == null ? null : Feeling.values.byName(name);

  int? get _habitId {
    final projects = ref.read(projectsProvider);
    return projects.hasProject ? projects.current.id : null;
  }

  /// Saves today's results, keeping the feeling if the log card was saved.
  void _saveToday(Map<int, TaskResult> results, {Feeling? feeling}) {
    final habit = _habitId;
    if (habit == null) return;
    final today = dayKey(DateTime.now());
    final saved = state.history.where((e) => dayKey(e.date) == today);
    final kept = feeling ?? (saved.isEmpty ? null : saved.first.feeling);
    ref
        .read(databaseProvider)
        .saveDay(
          habit,
          date: today,
          results: _encodeResults(results),
          feeling: kept?.name,
        );
  }

  /// Starts today with the tasks the user agreed to in the level step.
  void startDay(List<String> tasks) {
    state = state.copyWith(tasks: tasks, results: const {});
    planTasks(tasks);
  }

  /// Saves tasks as the plan without changing today. A bigger or smaller step
  /// the user agreed to applies from tomorrow.
  void planTasks(List<String> tasks) {
    final habit = _habitId;
    if (habit == null) return;
    ref
        .read(databaseProvider)
        .savePlan(habit, stageIndex: state.stageIndex, tasks: tasks);
  }

  /// Sets one task's result in today's log: null clears it.
  void setResult(int index, TaskResult? result) {
    final results = Map<int, TaskResult>.of(state.results);
    if (result == null) {
      results.remove(index);
    } else {
      results[index] = result;
    }
    state = state.copyWith(results: results);
    _saveToday(results);
  }

  /// Ticking a task marks it done. Ticking again clears it.
  void toggleTask(int index) {
    final results = Map<int, TaskResult>.of(state.results);
    if (results[index] == TaskResult.done) {
      results.remove(index);
    } else {
      results[index] = TaskResult.done;
    }
    state = state.copyWith(results: results);
    _saveToday(results);
  }

  /// Deletes the plan's day data: today's tasks and the stage.
  void clearPlan() {
    state = state.copyWith(tasks: const [], stageIndex: 0);
    final habit = _habitId;
    if (habit != null) ref.read(databaseProvider).clearPlan(habit);
  }

  /// Deletes every saved day.
  void clearLog() {
    state = state.copyWith(history: const [], results: const {});
    final habit = _habitId;
    if (habit != null) ref.read(databaseProvider).clearLog(habit);
  }

  /// Deletes everything this controller holds.
  void clearAll() => state = const DayState();

  /// Hard stop on or off. Paused means no steps and no reminders.
  void setPaused(bool paused) {
    state = state.copyWith(paused: paused);
    final habit = _habitId;
    if (habit != null) {
      ref.read(databaseProvider).updateHabit(habit, {'paused': paused ? 1 : 0});
    }
  }

  /// Saves the log card for today.
  void saveLog(Map<int, TaskResult> results, Feeling feeling) {
    final today = DateTime.now();
    state = state.copyWith(
      results: results,
      history: [
        DayEntry(date: today, results: results, feeling: feeling),
        ...state.history.where((e) => dayKey(e.date) != dayKey(today)),
      ],
    );
    _saveToday(results, feeling: feeling);
  }
}

final dayProvider = NotifierProvider<DayController, DayState>(
  DayController.new,
);
