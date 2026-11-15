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

/// Placeholder strings. Sinhala values are stand-ins until the native
/// speaker review. Screens read text through [tr], never inline literals.
const Map<String, Map<AppLanguage, String>> _strings = {
  'app.name': {AppLanguage.en: 'Habit Agent', AppLanguage.si: 'Habit Agent'},
  'lang.label': {AppLanguage.en: 'English', AppLanguage.si: 'සිංහල'},
};

/// Looks up a string key in the given language.
/// Falls back to English, then to the key itself, so a missing string is visible.
String tr(String key, AppLanguage language) {
  final entry = _strings[key];
  if (entry == null) return key;
  return entry[language] ?? entry[AppLanguage.en] ?? key;
}
