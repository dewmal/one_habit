import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_state.dart';
import '../app/rules.dart';
import '../i18n/language.dart';
import '../plugins/fitness_plugin.dart';

/// One tappable answer under a message.
class ChatReply {
  const ChatReply({required this.value, required this.label});

  final String value;
  final Map<AppLanguage, String> label;
}

/// One bubble. Text is kept for every language so the chat re-translates
/// when the user switches language.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.fromAgent,
    required this.text,
    this.questionLabel,
    this.replies = const [],
  });

  final int id;
  final bool fromAgent;
  final Map<AppLanguage, String> text;
  final Map<AppLanguage, String>? questionLabel;
  final List<ChatReply> replies;
}

enum OnboardingStep { askGoal, questions, healthCheck }

class ChatState {
  const ChatState({
    required this.messages,
    this.step = OnboardingStep.askGoal,
    this.questionIndex = 0,
    this.answers = const {},
    this.goal,
  });

  final List<ChatMessage> messages;
  final OnboardingStep step;

  /// Index into the plugin's placement questions.
  final int questionIndex;

  /// Placement question id -> chosen value (option id or typed text).
  final Map<String, String> answers;
  final String? goal;

  ChatState copyWith({
    List<ChatMessage>? messages,
    OnboardingStep? step,
    int? questionIndex,
    Map<String, String>? answers,
    String? goal,
  }) => ChatState(
    messages: messages ?? this.messages,
    step: step ?? this.step,
    questionIndex: questionIndex ?? this.questionIndex,
    answers: answers ?? this.answers,
    goal: goal ?? this.goal,
  );
}

/// The General chat. In onboarding it asks the goal and up to 5 questions in total.
class ChatController extends Notifier<ChatState> {
  int _seq = 0;

  @override
  ChatState build() => _initial();

  /// Clears the chat, used after "Delete everything".
  void reset() => state = _initial();

  ChatState _initial() =>
      ChatState(messages: [_agent(textOf('chat.greeting'))]);

  ChatMessage _agent(
    Map<AppLanguage, String> text, {
    Map<AppLanguage, String>? questionLabel,
    List<ChatReply> replies = const [],
  }) => ChatMessage(
    id: _seq++,
    fromAgent: true,
    text: filterOutgoing(text),
    questionLabel: questionLabel,
    replies: replies,
  );

  void _append(ChatMessage message) =>
      state = state.copyWith(messages: [...state.messages, message]);

  void _say(Map<AppLanguage, String> text) => _append(_agent(text));

  int get _placementCount => fitnessPlugin.placementQuestions.length;

  void _askQuestion(int index) {
    final question = fitnessPlugin.placementQuestions[index];
    _append(
      _agent(
        question.text,
        questionLabel: textOf('chat.question_label', {
          'n': '${index + 2}',
          'total': '${_placementCount + 1}',
        }),
        replies: [
          for (final option in question.options)
            ChatReply(value: option.id, label: option.label),
        ],
      ),
    );
  }

  /// The user typed text, or tapped a quick reply (pass [reply]).
  void send(String raw, {ChatReply? reply}) {
    final text = raw.trim();
    if (text.isEmpty && reply == null) return;

    _append(
      ChatMessage(
        id: _seq++,
        fromAgent: false,
        text: reply?.label ?? {AppLanguage.en: text, AppLanguage.si: text},
      ),
    );

    if (ref.read(appProvider).phase != AppPhase.onboarding) {
      _say(textOf('chat.noted'));
      return;
    }

    switch (state.step) {
      case OnboardingStep.askGoal:
        state = state.copyWith(goal: text, step: OnboardingStep.questions);
        _say(textOf('chat.good_goal'));
        _askQuestion(0);
      case OnboardingStep.questions:
        final question = fitnessPlugin.placementQuestions[state.questionIndex];
        final answers = {...state.answers, question.id: reply?.value ?? text};
        final next = state.questionIndex + 1;
        if (next < _placementCount) {
          state = state.copyWith(answers: answers, questionIndex: next);
          _askQuestion(next);
        } else {
          state = state.copyWith(
            answers: answers,
            step: OnboardingStep.healthCheck,
          );
          _say(textOf('chat.health_next'));
        }
      case OnboardingStep.healthCheck:
        break;
    }
  }
}

final chatProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);
