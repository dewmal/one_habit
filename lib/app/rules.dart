import '../i18n/language.dart';

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
