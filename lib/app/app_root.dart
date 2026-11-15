import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/chat_page.dart';
import '../screens/welcome_page.dart';
import 'app_state.dart';

/// Picks the screen for the current phase.
class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(appProvider.select((s) => s.phase));
    switch (phase) {
      case AppPhase.welcome:
        return const WelcomePage();
      case AppPhase.onboarding:
      case AppPhase.main:
        // The bottom nav joins in the Today screen commit.
        return const ChatPage();
    }
  }
}
