import '../i18n/language.dart';
import 'day_state.dart';

/// Dummy content for the screens until the gateway and database are wired.
/// Task wording comes from the plugin's sample tasks, not from screen code.
const _dummySteps = {
  'beginner': [
    'Pack your gym bag tonight',
    'Walk to the gym door',
    'Stay for 5 minutes',
  ],
  'building': [
    'Pack your gym bag tonight',
    'Walk to the gym door',
    'Stay for 10 minutes',
  ],
  'ready': ['Go to the gym', 'Do 15 minutes of work', 'Stretch for 5 minutes'],
};

List<String> dummyStepsFor(String level) =>
    List<String>.of(_dummySteps[level] ?? _dummySteps['beginner']!);

/// Text helpers used by the dummy screens.
Map<AppLanguage, String> dummyText(String english) => {
  AppLanguage.en: english,
  AppLanguage.si: english,
};

/// The project name shown on Today, from the user's project (dummy).
final dummyProjectName = dummyText('Improve my fitness');

/// Five past days, newest first, in the same shape as the History design.
List<DayEntry> dummyHistory(DateTime today) {
  DateTime daysAgo(int n) => DateTime(today.year, today.month, today.day - n);
  return [
    DayEntry(
      date: daysAgo(1),
      results: const {
        0: TaskResult.done,
        1: TaskResult.done,
        2: TaskResult.done,
      },
      feeling: Feeling.easy,
    ),
    DayEntry(
      date: daysAgo(2),
      results: const {0: TaskResult.done},
      feeling: Feeling.okay,
    ),
    DayEntry(date: daysAgo(3)),
    DayEntry(
      date: daysAgo(4),
      results: const {
        0: TaskResult.skipped,
        1: TaskResult.skipped,
        2: TaskResult.skipped,
      },
      feeling: Feeling.hard,
    ),
    DayEntry(
      date: daysAgo(5),
      results: const {
        0: TaskResult.done,
        1: TaskResult.done,
        2: TaskResult.partly,
      },
      feeling: Feeling.okay,
    ),
  ];
}
