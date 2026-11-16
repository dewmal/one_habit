import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_preccent/ai/llm_client.dart';
import 'package:one_preccent/main.dart';

import '../support/test_llm_client.dart';

/// Every call fails the way a dropped connection does.
class _OfflineClient implements LlmClient {
  @override
  Future<AgentSuggestion> chatReply({
    required String language,
    required String summary,
    required List<ChatTurn> history,
  }) => throw const AiException('no_connection');

  @override
  Future<List<String>> writeTasks({
    required String language,
    required String level,
    required String taskGuide,
  }) => throw const AiException('no_connection');
}

void main() {
  testWidgets(
    'offline gateway shows the calm message and still shows fixed steps',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: testAiOverrides(client: _OfflineClient()),
          child: const HabitAgentApp(),
        ),
      );
      await tester.tap(find.text('Start'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Gym every day');
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump();
      await tester.tap(find.text('Most days'));
      await tester.pump();
      await tester.tap(find.text('15 minutes'));
      await tester.pump();
      await tester.tap(find.text('Evening'));
      await tester.pump();
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('No'));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(find.text('No connection. Please try again.'), findsOneWidget);
      expect(find.text('Go to the gym'), findsOneWidget);
    },
  );
}
