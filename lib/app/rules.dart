import 'package:flutter/material.dart';

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

/// A bigger step never happens without the user's yes.
bool canStepUp({required bool userSaidYes}) => userSaidYes;

/// Words that mean "unwell" or "very low". Placeholder list: the detection
/// method (word list, AI flag or both) is still open (due Thu Nov 26).
const hardStopWords = [
  'unwell',
  'very low',
  'feel low',
  'feel really low',
  'feeling low',
  'not well',
];

/// The hard stop is triggered here, in code, never by the AI.
bool isHardStop(String text) {
  final lower = text.toLowerCase();
  return hardStopWords.any(lower.contains);
}

/// Whether [now] falls inside quiet hours. Quiet hours can cross midnight.
bool inQuietHours(TimeOfDay now, TimeOfDay start, TimeOfDay end) {
  final n = now.hour * 60 + now.minute;
  final s = start.hour * 60 + start.minute;
  final e = end.hour * 60 + end.minute;
  if (s <= e) return n >= s && n < e;
  return n >= s || n < e;
}

/// A reminder is sent only under the daily limit and outside quiet hours.
bool canSendReminder({
  required TimeOfDay now,
  required int sentToday,
  required int dailyLimit,
  required TimeOfDay quietStart,
  required TimeOfDay quietEnd,
}) {
  if (sentToday >= dailyLimit) return false;
  if (inQuietHours(now, quietStart, quietEnd)) return false;
  return true;
}
