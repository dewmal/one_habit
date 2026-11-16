import 'package:one_preccent/plugins/habit_plugin.dart';
import 'package:one_preccent/ai/llm_client.dart';
import 'package:one_preccent/plugins/fitness_plugin.dart';
import 'package:one_preccent/chat/chat_controller.dart';
import 'package:one_preccent/data/database_provider.dart';
import 'package:one_preccent/data/startup.dart';

import 'memory_database.dart';

/// Fixed answers for widget tests. It never touches the network. The app
/// itself has no fake: it always asks the gateway.
class TestLlmClient implements LlmClient {
  @override
  Future<AgentSuggestion> chatReply({
    required String language,
    required String summary,
    required List<ChatTurn> history,
  }) async =>
      const AgentSuggestion(text: 'Thanks for telling me. Small steps.');

  @override
  Future<List<String>> writeTasks({
    required String language,
    required String level,
    required String taskGuide,
  }) async => fitnessPlugin.fallbackStepsFor(level);
}

/// Overrides every widget test needs: no gateway calls, and a fresh in-memory
/// database that already holds one habit with its General chat (an install
/// that was closed before the first questions were answered).
// The override list type comes from Riverpod; it is not imported here.
// ignore: strict_top_level_inference
testAiOverrides({MemoryAppDatabase? database, LlmClient? client}) {
  final db = database ?? seededDatabase();
  return [
    llmProvider.overrideWithValue(client ?? TestLlmClient()),
    databaseProvider.overrideWithValue(db),
    startupOverride(
      Startup(
        habits: db.tables['habit']!,
        chats: db.tables['chat']!,
        generalMessages: db.tables['chat_message']!,
        plan: db.tables['plan']!.firstOrNull,
        logs: [...db.tables['daily_log']!]
          ..sort(
            (a, b) =>
                (b['log_date'] as String).compareTo(a['log_date'] as String),
          ),
        profile: db.tables['profile']!.firstOrNull,
      ),
    ),
  ];
}

/// One habit "Improve my fitness" with its General chat. Ids are 1.
MemoryAppDatabase seededDatabase({String? goal}) {
  final db = MemoryAppDatabase();
  db.createHabit(pluginId: 'fitness', name: 'Improve my fitness');
  if (goal != null) db.updateHabit(1, {'goal': goal, 'level': 'beginner'});
  db.createChat(1, 'general', 'General');
  return db;
}
