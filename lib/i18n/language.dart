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
  'notif.app': {AppLanguage.en: 'Habit Agent'},
  'notif.morning_title': {AppLanguage.en: "Today's small step"},
  'notif.morning_body': {AppLanguage.en: '{task}. That is all for now.'},
  'notif.nothing_today': {AppLanguage.en: 'Nothing planned for today.'},
  'notif.evening_body': {
    AppLanguage.en: 'Tap to log it. It takes a few seconds.',
  },
  'notif.later': {AppLanguage.en: 'Later'},
  'notif.too_hard': {AppLanguage.en: 'Too hard'},
  'data.title': {AppLanguage.en: 'My data'},
  'data.intro': {
    AppLanguage.en: 'All of this is saved only on this phone. You can look at it or delete it any time.',
  },
  'data.about': {AppLanguage.en: 'About you'},
  'data.about_desc': {AppLanguage.en: 'Language, quiet hours, reminders'},
  'data.habit': {AppLanguage.en: 'The habit'},
  'data.habit_desc': {AppLanguage.en: 'Goal, level, health check result'},
  'data.plan': {AppLanguage.en: 'The plan'},
  'data.plan_desc': {AppLanguage.en: 'Stages and current stage'},
  'data.log': {AppLanguage.en: 'Daily log'},
  'data.log_desc': {AppLanguage.en: "Each day's results and how it felt"},
  'data.chat': {AppLanguage.en: 'Chat history'},
  'data.chat_desc': {AppLanguage.en: 'Messages with your coach'},
  'data.view': {AppLanguage.en: 'View'},
  'data.delete': {AppLanguage.en: 'Delete'},
  'data.delete_means': {
    AppLanguage.en: 'Delete means delete. It cannot be undone.',
  },
  'data.delete_all': {AppLanguage.en: 'Delete everything'},
  'data.confirm_title': {AppLanguage.en: 'Delete this?'},
  'data.confirm_all_title': {AppLanguage.en: 'Delete everything?'},
  'data.confirm_body': {
    AppLanguage.en: 'It is removed from this phone right away.',
  },
  'data.confirm_all_body': {
    AppLanguage.en:
        'All saved data is removed and the app goes back to the first screen.',
  },
  'data.confirm_yes': {AppLanguage.en: 'Delete'},
  'data.cancel': {AppLanguage.en: 'Cancel'},
  'data.close': {AppLanguage.en: 'Close'},
  'data.view_title': {AppLanguage.en: 'Saved on this phone'},
  'data.none': {AppLanguage.en: 'Nothing saved yet'},
  'settings.title': {AppLanguage.en: 'Settings'},
  'settings.language': {AppLanguage.en: 'Language'},
  'settings.reminders': {AppLanguage.en: 'Reminders'},
  'settings.most_reminders': {AppLanguage.en: 'Most reminders a day'},
  'settings.morning': {AppLanguage.en: 'Morning reminder'},
  'settings.evening': {AppLanguage.en: 'Evening reminder'},
  'settings.quiet': {AppLanguage.en: 'Quiet hours'},
  'settings.privacy': {AppLanguage.en: 'Privacy'},
  'settings.my_data': {AppLanguage.en: 'My data'},
  'settings.lost_phone': {
    AppLanguage.en: 'Everything is saved only on this phone. If the phone is lost, your progress is lost too. Backup comes in a later version.',
  },
  // Fixed care message. Wording needs approval (due Thu Nov 26).
  'hardstop.care': {
    AppLanguage.en: "Thank you for telling me. Let's pause everything. No steps and no reminders until you are ready.",
  },
  'hardstop.title': {AppLanguage.en: 'Everything is paused'},
  'hardstop.body': {
    AppLanguage.en: 'No steps and no reminders. Your plan is safe and stays where it is. If you feel unwell or very low, please talk to a doctor or someone you trust.',
  },
  'hardstop.keep': {AppLanguage.en: 'Keep it paused'},
  'hardstop.resume': {AppLanguage.en: "I'm okay to continue"},
  'hardstop.keep_ack': {
    AppLanguage.en: 'Okay. Everything stays paused for now.',
  },
  'hardstop.resume_ack': {
    AppLanguage.en: 'Good. Tasks and reminders are back on.',
  },
  // Fixed step-up question. Wording needs approval (due Tue Nov 24).
  'stepup.question': {AppLanguage.en: 'Ready for a bit more?'},
  'stepup.reason': {
    AppLanguage.en:
        'You did your steps five days in a row and said they felt easy.',
  },
  'stepup.now': {AppLanguage.en: 'Now: {step}'},
  'stepup.bigger': {AppLanguage.en: 'A bit more: {step}'},
  'stepup.yes': {AppLanguage.en: 'Yes'},
  'stepup.not_yet': {AppLanguage.en: 'Not yet'},
  'stepup.nothing_changes': {
    AppLanguage.en: 'Nothing changes unless you say yes.',
  },
  'stepup.yes_ack': {AppLanguage.en: 'Done. The bigger step starts tomorrow.'},
  'stepup.not_yet_ack': {AppLanguage.en: 'No problem. Nothing changed.'},
  // Fixed phrase for a missed day. Wording needs approval (due Tue Nov 24).
  'missed.phrase': {
    AppLanguage.en:
        'Missed days happen. Nothing is lost and your plan stays where it is.',
  },
  'missed.made_smaller': {
    AppLanguage.en: 'I made tomorrow smaller, so it is easy to start again.',
  },
  'missed.card_heading': {AppLanguage.en: "Tomorrow's small step"},
  'missed.smaller': {AppLanguage.en: 'Smaller'},
  'missed.comparison': {AppLanguage.en: 'Was: {was} steps. Now: {now} step.'},
  'missed.okay': {AppLanguage.en: 'Okay'},
  'missed.still_much': {AppLanguage.en: 'Still too much'},
  'missed.okay_ack': {AppLanguage.en: 'Good. See you tomorrow.'},
  'history.title': {AppLanguage.en: 'History'},
  'history.subtitle': {AppLanguage.en: 'Your logs, newest first'},
  'history.today': {AppLanguage.en: 'Today'},
  'history.yesterday': {AppLanguage.en: 'Yesterday'},
  'history.rest': {AppLanguage.en: 'Rest day, nothing logged'},
  'history.all_done': {AppLanguage.en: 'All {n} steps done'},
  'history.all_skipped': {AppLanguage.en: 'All {n} steps skipped'},
  'history.done': {AppLanguage.en: '{n} done'},
  'history.partly': {AppLanguage.en: '{n} partly'},
  'history.skipped': {AppLanguage.en: '{n} skipped'},
  'history.not_logged': {AppLanguage.en: '{n} not logged yet'},
  'weekday.1': {AppLanguage.en: 'Monday'},
  'weekday.2': {AppLanguage.en: 'Tuesday'},
  'weekday.3': {AppLanguage.en: 'Wednesday'},
  'weekday.4': {AppLanguage.en: 'Thursday'},
  'weekday.5': {AppLanguage.en: 'Friday'},
  'weekday.6': {AppLanguage.en: 'Saturday'},
  'weekday.7': {AppLanguage.en: 'Sunday'},
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
