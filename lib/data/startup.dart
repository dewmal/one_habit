import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// What is read from the database once, before the first frame, so the
/// controllers can build without waiting. Each controller then writes every
/// change back to the database.
class Startup {
  const Startup({
    this.habits = const [],
    this.chats = const [],
    this.generalMessages = const [],
    this.plan,
    this.logs = const [],
    this.profile,
  });

  /// Habit rows, oldest first.
  final List<Map<String, Object?>> habits;

  /// Chat rows of every habit, as returned by `chatsOf`.
  final List<Map<String, Object?>> chats;

  /// Messages of the first habit's General chat, oldest first.
  final List<Map<String, Object?>> generalMessages;

  /// The first habit's plan row and daily log (newest first).
  final Map<String, Object?>? plan;
  final List<Map<String, Object?>> logs;

  /// The profile row: language and settings.
  final Map<String, Object?>? profile;

  static Future<Startup> load(AppDatabase db) async {
    final profile = await db.profile();
    final habits = await db.habits();
    if (habits.isEmpty) return Startup(profile: profile);
    final chats = <Map<String, Object?>>[];
    for (final habit in habits) {
      chats.addAll(await db.chatsOf(habit['id'] as int));
    }
    var messages = const <Map<String, Object?>>[];
    for (final c in chats) {
      if (c['habit_id'] == habits.first['id'] && c['kind'] == 'general') {
        messages = await db.messagesOf(c['id'] as int);
      }
    }
    final first = habits.first['id'] as int;
    return Startup(
      habits: habits,
      chats: chats,
      generalMessages: messages,
      plan: await db.planOf(first),
      logs: await db.logsOf(first),
      profile: profile,
    );
  }
}

/// Overridden in main() with [Startup.load], and in tests with seeded rows.
final startupProvider = Provider<Startup>((ref) => const Startup());
