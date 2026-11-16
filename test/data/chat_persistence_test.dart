import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_preccent/app/app_state.dart';
import 'package:one_preccent/app/projects.dart';
import 'package:one_preccent/chat/chat_controller.dart';
import 'package:one_preccent/data/database_provider.dart';
import 'package:one_preccent/data/startup.dart';
import 'package:one_preccent/i18n/language.dart';

import '../support/memory_database.dart';
import '../support/test_llm_client.dart';

void main() {
  /// A fresh app run on top of the same database, as after a restart.
  Future<ProviderContainer> launch(MemoryAppDatabase db) async {
    final startup = await Startup.load(db);
    final container = ProviderContainer(
      overrides: [
        llmProvider.overrideWithValue(TestLlmClient()),
        databaseProvider.overrideWithValue(db),
        startupProvider.overrideWithValue(startup),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  test('messages and cards are still there after a restart', () async {
    final db = MemoryAppDatabase();
    final first = await launch(db);
    expect(first.read(appProvider).phase, AppPhase.welcome);

    await first.read(appProvider.notifier).startOnboarding();
    first.read(chatProvider.notifier).send('Gym every day');
    await settle();

    final rows = await db.messagesOf(1);
    expect(rows.map((r) => r['kind']), [
      'fixed',
      'text',
      'text',
      'fixed',
      'card',
    ]);
    expect(rows.first['text_key'], 'chat.greeting');
    expect(rows.last['card_type'], 'question');

    // Onboarding finished: the level marks the habit as done.
    await db.updateHabit(1, {'level': 'beginner'});
    final second = await launch(db);
    expect(second.read(appProvider).phase, AppPhase.main);
    final messages = second.read(chatProvider).messages;
    expect(messages.length, rows.length);
    expect(messages.last.card, isA<QuestionCardData>());
    expect(messages.last.replies, isNotEmpty);
    expect(second.read(chatProvider).goal, 'Gym every day');
  });

  test('a saved phrase follows the app language', () async {
    final db = MemoryAppDatabase();
    final app = await launch(db);
    await app.read(appProvider.notifier).startOnboarding();
    final message = app.read(chatProvider).messages.first;
    expect(message.text, textOf('chat.greeting'));
  });

  test('starting again clears an unfinished General chat', () async {
    final db = MemoryAppDatabase();
    final first = await launch(db);
    await first.read(appProvider.notifier).startOnboarding();
    first.read(chatProvider.notifier).send('Old goal');
    await settle();

    final second = await launch(db);
    await second.read(appProvider.notifier).startOnboarding();
    final rows = await db.messagesOf(1);
    expect(rows.length, 1);
    expect(rows.single['text_key'], 'chat.greeting');
    expect(second.read(projectsProvider).projects.length, 1);
  });
}
