import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The shared "About you" settings: reminders and quiet hours.
class SettingsState {
  const SettingsState({
    this.dailyLimit = 2,
    this.morning = const TimeOfDay(hour: 7, minute: 0),
    this.evening = const TimeOfDay(hour: 19, minute: 30),
    this.quietStart = const TimeOfDay(hour: 21, minute: 0),
    this.quietEnd = const TimeOfDay(hour: 7, minute: 0),
  });

  /// Most reminders a day, across all projects.
  final int dailyLimit;
  final TimeOfDay morning;
  final TimeOfDay evening;
  final TimeOfDay quietStart;
  final TimeOfDay quietEnd;

  SettingsState copyWith({
    int? dailyLimit,
    TimeOfDay? morning,
    TimeOfDay? evening,
    TimeOfDay? quietStart,
    TimeOfDay? quietEnd,
  }) => SettingsState(
    dailyLimit: dailyLimit ?? this.dailyLimit,
    morning: morning ?? this.morning,
    evening: evening ?? this.evening,
    quietStart: quietStart ?? this.quietStart,
    quietEnd: quietEnd ?? this.quietEnd,
  );
}

/// Bounds for "Most reminders a day". Placeholder limits until the notification task.
const minDailyLimit = 1;
const maxDailyLimit = 5;

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() => const SettingsState();

  void changeDailyLimit(int delta) {
    final next = (state.dailyLimit + delta).clamp(minDailyLimit, maxDailyLimit);
    state = state.copyWith(dailyLimit: next);
  }

  void setMorning(TimeOfDay time) => state = state.copyWith(morning: time);

  void setEvening(TimeOfDay time) => state = state.copyWith(evening: time);

  void setQuiet({required TimeOfDay start, required TimeOfDay end}) =>
      state = state.copyWith(quietStart: start, quietEnd: end);
}

final settingsProvider = NotifierProvider<SettingsController, SettingsState>(
  SettingsController.new,
);

/// "7:00 AM" style, for the setting rows.
String formatTime(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}
