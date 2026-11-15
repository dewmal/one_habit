import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_preccent/i18n/language.dart';
import 'package:one_preccent/main.dart';

void main() {
  testWidgets('app shell shows the app name and follows the language',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HabitAgentApp()));
    expect(find.text('Habit Agent'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(HabitAgentApp)),
    );
    container.read(languageProvider.notifier).toggle();
    await tester.pump();
    expect(find.text('Habit Agent'), findsOneWidget);
  });
}
