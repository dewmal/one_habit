import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/startup.dart';
import '../chat/chat_controller.dart';
import 'projects.dart';

/// Where the user is in the app. Welcome first, then onboarding chat, then the tabs.
enum AppPhase { welcome, onboarding, main }

class AppState {
  const AppState({this.phase = AppPhase.welcome});

  final AppPhase phase;

  AppState copyWith({AppPhase? phase}) => AppState(phase: phase ?? this.phase);
}

class AppController extends Notifier<AppState> {
  @override
  AppState build() {
    // A habit with a level means onboarding was finished. Anything else starts
    // again from Welcome.
    final done = ref
        .watch(startupProvider)
        .habits
        .any((h) => h['level'] != null);
    return AppState(phase: done ? AppPhase.main : AppPhase.welcome);
  }

  /// Welcome "Start" button. The habit and its General chat are saved first.
  Future<void> startOnboarding() async {
    await ref.read(projectsProvider.notifier).ensureHabit();
    await ref.read(chatProvider.notifier).beginOnboarding();
    state = state.copyWith(phase: AppPhase.onboarding);
  }

  /// Level card "Looks good": the user enters the main app.
  void finishOnboarding() => state = state.copyWith(phase: AppPhase.main);
}

final appProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);
