// Runs the real app against the real gateway. Nothing is faked.
//
// Start the gateway first (cd server && go run .), then:
//   flutter test integration_test -d macos \
//     --dart-define=GATEWAY_URL=http://127.0.0.1:8080/chat
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:one_preccent/chat/chat_controller.dart';
import 'package:one_preccent/i18n/language.dart';
import 'package:one_preccent/main.dart';

/// Pumps until [finder] shows. The gateway may take up to 60 seconds.
Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 700; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboarding screens are built from live gateway answers', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: HabitAgentApp()));
    await tester.tap(find.text('Start'));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Walk every day');
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await _waitFor(tester, find.text('Question 2 of 5'));

    for (final (answer, next) in [
      ('Once or twice a week', 'Question 3 of 5'),
      ('5 minutes', 'Question 4 of 5'),
      ('Morning', 'Question 5 of 5'),
    ]) {
      await tester.tap(find.text(answer));
      await _waitFor(tester, find.text(next));
    }
    await tester.tap(find.text('Yes'));
    await _waitFor(tester, find.text('Quick health check'));
    await tester.pumpAndSettle();

    // The health check is plain code on the phone. No gateway call.
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('No').last);
      await tester.pump();
    }
    // The level card shows the steps the AI wrote.
    await _waitFor(tester, find.text('Looks good'));

    final chat = ProviderScope.containerOf(
      tester.element(find.byType(HabitAgentApp)),
    ).read(chatProvider);
    final shown = [for (final m in chat.messages) m.text[AppLanguage.en]];
    for (final key in [
      'chat.no_connection',
      'chat.rate_limited',
      'chat.too_large',
      'chat.try_again',
    ]) {
      expect(shown, isNot(contains(tr(key, AppLanguage.en))));
    }
    expect(chat.steps, isNotEmpty);
    debugPrint('Chat: $shown');
    debugPrint('Steps from the AI: ${chat.steps}');
  });
}
