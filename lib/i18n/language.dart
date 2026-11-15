import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage { en, si }

/// Holds the current language. Changing it updates every watching widget at once.
/// Persisting it to the profile table is added with the database task.
class LanguageController extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => AppLanguage.en;

  void set(AppLanguage language) => state = language;

  void toggle() =>
      state = state == AppLanguage.en ? AppLanguage.si : AppLanguage.en;
}

final languageProvider = NotifierProvider<LanguageController, AppLanguage>(
  LanguageController.new,
);

/// Placeholder strings. Only English is written so far: a missing Sinhala
/// value falls back to English until the Sinhala text is written (Fri Nov 27).
/// Screens read text through [tr] or [textOf], never inline literals.
const Map<String, Map<AppLanguage, String>> _strings = {
  'app.name': {AppLanguage.en: 'Habit Agent', AppLanguage.si: 'Habit Agent'},
  'lang.label': {AppLanguage.en: 'English', AppLanguage.si: 'සිංහල'},
  'welcome.promise': {
    AppLanguage.en:
        "One small step a day. I'll help you build a habit that lasts.",
  },
  'welcome.ai_note': {
    AppLanguage.en:
        "I'm an AI coach, not a person. What you tell me stays on this phone.",
  },
  'welcome.start': {AppLanguage.en: 'Start'},
  'chat.general': {AppLanguage.en: 'General'},
  'chat.coach': {AppLanguage.en: 'Your coach · AI'},
  'chat.greeting': {AppLanguage.en: 'Hi! What habit would you like to build?'},
  'chat.good_goal': {
    AppLanguage.en:
        'Good goal. A few short questions so the first step fits you.',
  },
  'chat.question_label': {AppLanguage.en: 'Question {n} of {total}'},
  'chat.health_next': {AppLanguage.en: 'Thanks. Next, a quick health check.'},
  'chat.noted': {AppLanguage.en: 'Noted.'},
  'health.title': {AppLanguage.en: 'Quick health check'},
  'health.question_label': {AppLanguage.en: 'Question {n} of {total}'},
  'health.no': {AppLanguage.en: 'No'},
  'health.yes': {AppLanguage.en: 'Yes'},
  'health.reassure': {
    AppLanguage.en: 'A "yes" only keeps your plan gentle. It never blocks you.',
  },
  'chat.safe_fallback': {
    AppLanguage.en: "Let's take it one small step at a time.",
  },
  'chat.input_hint': {AppLanguage.en: 'Type a message'},
  'nav.chat': {AppLanguage.en: 'Chat'},
  'nav.today': {AppLanguage.en: 'Today'},
  'nav.plan': {AppLanguage.en: 'Plan'},
  'nav.history': {AppLanguage.en: 'History'},
  'today.title': {AppLanguage.en: 'Today'},
  'today.settings': {AppLanguage.en: 'Settings'},
  'today.offline': {
    AppLanguage.en: "You're offline. Your steps and logging still work.",
  },
  'today.stage_of': {AppLanguage.en: 'Stage {n} of {total}'},
  'today.stage_line': {
    AppLanguage.en: '{n} small steps today. Any one of them counts.',
  },
  'today.log_button': {AppLanguage.en: 'Log how it went'},
  'plan.title': {AppLanguage.en: 'Plan'},
  'log.question': {AppLanguage.en: 'How did today go?'},
  'log.done': {AppLanguage.en: 'Done'},
  'log.partly': {AppLanguage.en: 'Partly'},
  'log.skipped': {AppLanguage.en: 'Skipped'},
  'log.feel': {AppLanguage.en: 'How did it feel?'},
  'log.easy': {AppLanguage.en: 'Easy'},
  'log.okay': {AppLanguage.en: 'Okay'},
  'log.hard': {AppLanguage.en: 'Hard'},
  'log.save': {AppLanguage.en: 'Save'},
  // Fixed phrase, same for Done and Skipped. Wording needs approval (due Mon Nov 23).
  'log.saved_reply': {
    AppLanguage.en: 'Thanks for logging today. Every day you show up counts.',
  },
  'plan.here': {AppLanguage.en: 'You are here'},
  'plan.goal': {AppLanguage.en: 'Your goal: {goal}'},
  'plan.note': {
    AppLanguage.en: 'This page is view only. Missed days never reset your plan. Changes happen in chat.',
  },
  'level.intro': {AppLanguage.en: 'Thanks. Here is where we start.'},
  'level.heading': {AppLanguage.en: 'Your starting level'},
  'level.steps_heading': {AppLanguage.en: "Tomorrow's small steps"},
  'level.looks_good': {AppLanguage.en: 'Looks good'},
  'level.smaller': {AppLanguage.en: 'Make it smaller'},
  'level.smaller_ack': {AppLanguage.en: 'Okay, I will make the steps smaller.'},
  'level.gentle_note': {
    AppLanguage.en: 'You said yes to a health question, so I will keep things gentle. Please see a doctor before doing more.',
  },
};

/// Looks up a string key in the given language.
/// Falls back to English, then to the key itself, so a missing string is visible.
String tr(String key, AppLanguage language) {
  final entry = _strings[key];
  if (entry == null) return key;
  return entry[language] ?? entry[AppLanguage.en] ?? key;
}

/// All languages of a key, with {placeholders} filled in. Used where text must
/// stay correct after the user switches language (chat history).
Map<AppLanguage, String> textOf(
  String key, [
  Map<String, String> params = const {},
]) {
  final base = _strings[key] ?? {AppLanguage.en: key};
  return base.map((language, value) {
    var filled = value;
    params.forEach((name, replacement) {
      filled = filled.replaceAll('{$name}', replacement);
    });
    return MapEntry(language, filled);
  });
}

/// Picks the text for [language], falling back to English.
String resolve(Map<AppLanguage, String> text, AppLanguage language) =>
    text[language] ?? text[AppLanguage.en] ?? '';
