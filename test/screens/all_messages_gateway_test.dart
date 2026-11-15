import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_preccent/ai/llm_client.dart';
import 'package:one_preccent/chat/chat_controller.dart';
import 'package:one_preccent/main.dart';

/// Records the history of every coach call the chat makes.
class _RecordingClient implements LlmClient {
  final List<List<ChatTurn>> calls = [];

  @override
  Future<AgentSuggestion> chatReply({
    required String language,
    required String summary,
    required List<ChatTurn> history,
  }) async {
    calls.add(history);
    return const AgentSuggestion(text: 'Nice to meet you.');
  }

  @override
  Future<List<String>> writeTasks({
    required String language,
    required String level,
    required String taskGuide,
  }) async => const ['Put on shoes'];
}

void main() {
  testWidgets('every onboarding message reaches the gateway as the newest '
      'user turn', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final client = _RecordingClient();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [llmProvider.overrideWithValue(client)],
        child: const HabitAgentApp(),
      ),
    );
    await tester.tap(find.text('Start'));
    await tester.pump();

    // A typed goal is a message.
    await tester.enterText(find.byType(TextField), 'Gym every day');
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pump();
    expect(client.calls, hasLength(1));
    expect(client.calls.last.last.role, 'user');
    expect(client.calls.last.last.content, 'Gym every day');

    // A tapped answer is a message too.
    await tester.tap(find.text('Most days'));
    await tester.pump();
    expect(client.calls, hasLength(2));
    expect(client.calls.last.last.role, 'user');
    expect(client.calls.last.last.content, 'Most days');
    expect(client.calls.last.first.role, 'user');
  });
}
