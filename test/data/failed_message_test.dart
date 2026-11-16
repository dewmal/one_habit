import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_preccent/ai/llm_client.dart';
import 'package:one_preccent/app/projects.dart';
import 'package:one_preccent/chat/chat_controller.dart';
import 'package:one_preccent/data/database_provider.dart';
import 'package:one_preccent/data/startup.dart';

import '../support/memory_database.dart';

/// Fails with the given codes in order, then answers.
class _Flaky implements LlmClient {
  _Flaky(this.failures);

  final List<String> failures;
  final lengths = <int>[];

  @override
  Future<AgentSuggestion> chatReply({
    required String language,
    required String summary,
    required List<ChatTurn> history,
  }) async {
    lengths.add(history.length);
    if (failures.isNotEmpty) throw AiException(failures.removeAt(0));
    return const AgentSuggestion(text: 'Here I am.');
  }

  @override
  Future<List<String>> writeTasks({
    required String language,
    required String level,
    required String taskGuide,
  }) async => const ['x'];
}

void main() {
  Future<(ProviderContainer, MemoryAppDatabase)> setup(_Flaky client) async {
    final db = MemoryAppDatabase();
    final habit = await db.createHabit(pluginId: 'fitness', name: 'Fitness');
    await db.createChat(habit, 'general', 'General');
    await db.updateHabit(habit, {'level': 'beginner'});
    final container = ProviderContainer(
      overrides: [
        llmProvider.overrideWithValue(client),
        databaseProvider.overrideWithValue(db),
        startupOverride(await Startup.load(db)),
      ],
    );
    addTearDown(container.dispose);
    return (container, db);
  }

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  test('a failed message is sent again and appears only once', () async {
    final (container, db) = await setup(_Flaky(['no_connection']));
    final chat = container.read(chatProvider.notifier);
    chat.send('Hello');
    await settle();

    var rows = await db.messagesOf(1);
    expect(rows.single['status'], 'failed');
    expect(container.read(chatProvider).messages.single.failed, isTrue);

    await chat.retry(rows.single['id'] as int);
    await settle();
    rows = await db.messagesOf(1);
    expect(rows.map((r) => r['role']), ['user', 'assistant']);
    expect(rows.first['status'], 'sent');
    expect(container.read(chatProvider).messages.first.failed, isFalse);
  });

  test('a failed message is left out of the next request', () async {
    final client = _Flaky(['no_connection']);
    final (container, _) = await setup(client);
    final chat = container.read(chatProvider.notifier);
    chat.send('Lost one');
    await settle();
    chat.send('Second');
    await settle();
    expect(client.lengths.last, 1);
  });

  test('rate_limited marks failed and shows the short break phrase', () async {
    final (container, db) = await setup(_Flaky(['rate_limited']));
    container.read(chatProvider.notifier).send('Hello');
    await settle();
    final rows = await db.messagesOf(1);
    expect(rows.first['status'], 'failed');
    expect(rows.last['text_key'], 'chat.rate_limited');
  });

  test('too_large retries once with the last 5 messages', () async {
    final client = _Flaky(['too_large']);
    final (container, db) = await setup(client);
    for (var i = 0; i < 4; i++) {
      await db.addMessage(1, i.isEven ? 'user' : 'assistant', text: 'old $i');
    }
    await db.addMessage(1, 'user', text: 'old 4');
    await db.addMessage(1, 'assistant', text: 'old 5');
    container.read(chatProvider.notifier).send('Newest');
    await settle();
    expect(client.lengths, [7, 5]);
    expect((await db.messagesOf(1)).last['text'], 'Here I am.');
  });

  test('topic chat: failed then retried without a second copy', () async {
    final client = _Flaky(['no_connection']);
    final (container, db) = await setup(client);
    await container.read(projectsProvider.notifier).startChat('Diet');
    final chatId = container.read(projectsProvider).currentChatId;
    final topics = container.read(topicChatsProvider.notifier);
    await topics.send(chatId, 'Diet', 'Hello');
    var rows = await db.messagesOf(chatId);
    expect(rows.single['status'], 'failed');

    await topics.retry(chatId, 'Diet', rows.single['id'] as int);
    rows = await db.messagesOf(chatId);
    expect(rows.map((r) => r['role']), ['user', 'assistant']);
  });
}
