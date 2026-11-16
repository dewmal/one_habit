import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_preccent/ai/llm_client.dart';
import 'package:one_preccent/app/projects.dart';
import 'package:one_preccent/chat/chat_controller.dart';
import 'package:one_preccent/data/database_provider.dart';
import 'package:one_preccent/data/startup.dart';

import '../support/memory_database.dart';

class _Recorder implements LlmClient {
  _Recorder({this.wantsBigger = false});

  final bool wantsBigger;
  final sent = <List<ChatTurn>>[];

  @override
  Future<AgentSuggestion> chatReply({
    required String language,
    required String summary,
    required List<ChatTurn> history,
  }) async {
    sent.add(history);
    return AgentSuggestion(text: 'ok ${sent.length}', wantsBigger: wantsBigger);
  }

  @override
  Future<List<String>> writeTasks({
    required String language,
    required String level,
    required String taskGuide,
  }) async => const ['x'];
}

void main() {
  Future<(ProviderContainer, MemoryAppDatabase, int)> setup(
    _Recorder client,
  ) async {
    final db = MemoryAppDatabase();
    final habit = await db.createHabit(pluginId: 'fitness', name: 'Fitness');
    await db.createChat(habit, 'general', 'General');
    await db.updateHabit(habit, {'level': 'beginner'});
    final container = ProviderContainer(
      overrides: [
        llmProvider.overrideWithValue(client),
        databaseProvider.overrideWithValue(db),
        startupProvider.overrideWithValue(await Startup.load(db)),
      ],
    );
    addTearDown(container.dispose);
    await container.read(projectsProvider.notifier).startChat('Diet');
    return (container, db, container.read(projectsProvider).currentChatId);
  }

  test('a long topic chat still sends only the last 10 messages', () async {
    final client = _Recorder();
    final (container, db, chat) = await setup(client);
    final topics = container.read(topicChatsProvider.notifier);
    for (var i = 0; i < 8; i++) {
      await topics.send(chat, 'Diet', 'message $i');
    }
    expect((await db.messagesOf(chat)).length, 16);
    final last = client.sent.last;
    expect(last.length, lessThanOrEqualTo(10));
    expect(last.first.role, 'user');
    expect(last.last.content, 'message 7');
  });

  test('a bigger step is only a pending flag until General opens', () async {
    final client = _Recorder(wantsBigger: true);
    final (container, db, chat) = await setup(client);
    await container.read(topicChatsProvider.notifier).send(chat, 'Diet', 'hi');

    var habit = (await db.habits()).single;
    expect(habit['pending_step_up'], 1);
    expect(await db.planOf(habit['id'] as int), isNull);

    container.read(topicChatsProvider.notifier).openGeneral();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    habit = (await db.habits()).single;
    expect(habit['pending_step_up'], 0);
    final general = container.read(projectsProvider).current.generalChat.id;
    final cards = (await db.messagesOf(general))
        .where((m) => m['card_type'] == 'step_up');
    expect(cards.length, 1);
  });
}
