import '../i18n/language.dart';
import '../plugins/habit_plugin.dart';

/// Plain-code rules. Every outgoing message passes through here.
/// The blocked list is a placeholder until the blocklist decision (due Fri Nov 20).
const blockedWords = [
  'you must',
  'streak',
  'hurry',
  'last chance',
  'you will lose',
  'you failed',
  'shame',
];

bool isBlocked(String text) {
  final lower = text.toLowerCase();
  return blockedWords.any(lower.contains);
}

/// Returns the message, or a calm fixed line if any language has blocked wording.
Map<AppLanguage, String> filterOutgoing(Map<AppLanguage, String> text) {
  if (text.values.any(isBlocked)) return textOf('chat.safe_fallback');
  return text;
}

/// Places the user on a starting level. A "Yes" in the health check always
/// gives the gentlest level, whatever the answers say.
String placeLevel(
  HabitPlugin plugin,
  Map<String, String> answers, {
  required bool healthLock,
}) {
  if (healthLock) return 'beginner';
  for (final question in plugin.placementQuestions) {
    for (final option in question.options) {
      if (option.id == answers[question.id] && option.level != null) {
        return option.level!;
      }
    }
  }
  return 'beginner';
}
