import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where the user is in the app. Welcome first, then onboarding chat, then the tabs.
enum AppPhase { welcome, onboarding, main }

class AppState {
  const AppState({this.phase = AppPhase.welcome});

  final AppPhase phase;

  AppState copyWith({AppPhase? phase}) => AppState(phase: phase ?? this.phase);
}

class AppController extends Notifier<AppState> {
  @override
  AppState build() => const AppState();

  /// Welcome "Start" button.
  void startOnboarding() => state = state.copyWith(phase: AppPhase.onboarding);

  /// Level card "Looks good": the user enters the main app.
  void finishOnboarding() => state = state.copyWith(phase: AppPhase.main);

  /// "Delete everything": back to the first screen.
  void resetToWelcome() => state = state.copyWith(phase: AppPhase.welcome);
}

final appProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);
