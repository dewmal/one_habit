import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens the side menu with the menu button.
Future<void> openMenu(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
}

/// Opens the side menu and taps one entry by its text.
Future<void> chooseInMenu(WidgetTester tester, String text) async {
  await openMenu(tester);
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}
