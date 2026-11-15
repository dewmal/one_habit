import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dummy_data.dart';

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

class DayController extends Notifier<DayState> {
  @override
  DayState build() => DayState(history: dummyHistory(DateTime.now()));

  /// Starts today with the tasks the user agreed to in the level step.
  void startDay(List<String> tasks) =>
      state = state.copyWith(tasks: tasks, results: const {});

  /// Sets one task's result in today's log: null clears it.
  void setResult(int index, TaskResult? result) {
    final results = Map<int, TaskResult>.of(state.results);
    if (result == null) {
      results.remove(index);
    } else {
      results[index] = result;
    }
    state = state.copyWith(results: results);
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
  }

  /// Deletes the plan's day data: today's tasks and the stage.
  void clearPlan() => state = state.copyWith(tasks: const [], stageIndex: 0);

  /// Deletes every saved day.
  void clearLog() =>
      state = state.copyWith(history: const [], results: const {});

  /// Deletes everything this controller holds.
  void clearAll() => state = const DayState();

  /// Hard stop on or off. Paused means no steps and no reminders.
  void setPaused(bool paused) => state = state.copyWith(paused: paused);

  /// Saves the log card for today.
  void saveLog(Map<int, TaskResult> results, Feeling feeling) {
    state = state.copyWith(results: results);
    final today = DayEntry(
      date: DateTime.now(),
      results: results,
      feeling: feeling,
    );
    state = state.copyWith(history: [today, ...state.history]);
  }
}

final dayProvider = NotifierProvider<DayController, DayState>(
  DayController.new,
);
