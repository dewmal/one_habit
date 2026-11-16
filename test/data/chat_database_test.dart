import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:one_preccent/data/app_database.dart';

void main() {
  sqfliteFfiInit();

  Future<AppDatabase> open() =>
      AppDatabase.openWithFactory(databaseFactoryFfi, inMemoryDatabasePath);

  test('chats list General first, then the newest topic chat', () async {
    final db = await open();
    final general = await db.createChat(1, 'general', 'General');
    final diet = await db.createChat(1, 'topic', 'Diet');
    final exercise = await db.createChat(1, 'topic', 'Exercise');
    await db.createChat(2, 'general', 'General');
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await db.addMessage(diet, 'user', text: 'hello');

    final chats = await db.chatsOf(1);
    expect([for (final c in chats) c['id']], [general, diet, exercise]);
  });

  test('messages keep order, cards keep their answer', () async {
    final db = await open();
    final chat = await db.createChat(1, 'general', 'General');
    await db.addMessage(chat, 'user', text: 'one');
    final card = await db.addMessage(
      chat,
      'assistant',
      kind: 'card',
      cardType: 'level',
      cardData: '{}',
    );
    await db.answerCard(card, 'looks_good');

    final rows = await db.messagesOf(chat);
    expect(rows.map((r) => r['kind']), ['text', 'card']);
    expect(rows.last['card_answer'], 'looks_good');
  });

  test(
    'recentTextMessages skips cards, fixed and failed, keeps the last 10',
    () async {
      final db = await open();
      final chat = await db.createChat(1, 'general', 'General');
      for (var i = 0; i < 14; i++) {
        await db.addMessage(chat, i.isEven ? 'user' : 'assistant', text: '$i');
      }
      await db.addMessage(
        chat,
        'assistant',
        kind: 'fixed',
        textKey: 'chat.noted',
      );
      final failed = await db.addMessage(chat, 'user', text: 'lost');
      await db.setStatus(failed, 'failed');

      final recent = await db.recentTextMessages(chat);
      expect(recent.length, 10);
      expect(recent.first['text'], '4');
      expect(recent.last['text'], '13');
    },
  );

  test('deleting a topic chat removes it, General keeps its row', () async {
    final db = await open();
    final general = await db.createChat(1, 'general', 'General');
    final topic = await db.createChat(1, 'topic', 'Diet');
    await db.addMessage(general, 'user', text: 'a');
    await db.addMessage(topic, 'user', text: 'b');

    await db.deleteChat(topic);
    await db.deleteChat(general);

    expect(await db.messagesOf(topic), isEmpty);
    expect(await db.messagesOf(general), isEmpty);
    final chats = await db.chatsOf(1);
    expect([for (final c in chats) c['id']], [general]);
  });

  test('habit has the new name and pending_step_up columns', () async {
    final db = await open();
    final rows = await db.rows('habit');
    expect(rows, isEmpty);
    expect(AppDatabase.tableNames, containsAll(['chat', 'chat_message']));
    expect(AppDatabase.tableNames, isNot(contains('chat_history')));
  });

  test('wipe leaves every table empty', () async {
    final db = await open();
    final habit = await db.createHabit(pluginId: 'fitness', name: 'Fitness');
    final chat = await db.createChat(habit, 'general', 'General');
    await db.addMessage(chat, 'user', text: 'a');
    await db.savePlan(habit, stageIndex: 0, tasks: ['x']);
    await db.saveDay(habit, date: '2026-11-16', results: '{}');
    await db.saveProfile({'language': 'en'});

    await db.wipe();

    for (final table in AppDatabase.tableNames) {
      expect(await db.rows(table), isEmpty, reason: table);
    }
  });

  test('deleting a habit removes its chats, messages, plan and log', () async {
    final db = await open();
    final habit = await db.createHabit(pluginId: 'fitness', name: 'Fitness');
    final chat = await db.createChat(habit, 'general', 'General');
    await db.addMessage(chat, 'user', text: 'a');
    await db.savePlan(habit, stageIndex: 0, tasks: ['x']);
    await db.saveDay(habit, date: '2026-11-16', results: '{}');
    await db.saveDay(habit, date: '2026-11-16', results: '{"0":"done"}');
    expect((await db.logsOf(habit)).length, 1);

    await db.deleteHabit(habit);

    for (final table in [
      'habit',
      'chat',
      'chat_message',
      'plan',
      'daily_log',
    ]) {
      expect(await db.rows(table), isEmpty, reason: table);
    }
  });
}
