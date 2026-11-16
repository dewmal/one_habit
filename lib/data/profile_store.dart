import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/settings_state.dart';
import '../i18n/language.dart';
import 'database_provider.dart';
import 'startup.dart';

String _time(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

TimeOfDay? parseTime(Object? value) {
  if (value is! String) return null;
  final parts = value.split(':');
  if (parts.length != 2) return null;
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

/// Writes the language and the settings to the one profile row. The owner of
/// a changing value passes it in, because a provider cannot read itself.
void saveProfile(
  Ref ref, {
  required AppLanguage language,
  required SettingsState settings,
}) {
  final s = settings;
  ref.read(databaseProvider).saveProfile({
    'language': language.name,
    'daily_limit': s.dailyLimit,
    'morning_time': _time(s.morning),
    'evening_time': _time(s.evening),
    'quiet_start': _time(s.quietStart),
    'quiet_end': _time(s.quietEnd),
  });
}

/// The profile row read at start, or null on a fresh install.
Map<String, Object?>? savedProfile(Ref ref) =>
    ref.read(startupProvider).profile;
