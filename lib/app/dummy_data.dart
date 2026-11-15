import '../i18n/language.dart';

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
