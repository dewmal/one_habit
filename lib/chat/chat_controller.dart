import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_state.dart';
import '../app/day_state.dart';
import '../app/dummy_data.dart';
import '../app/rules.dart';
import '../i18n/language.dart';
import '../plugins/fitness_plugin.dart';

/// One tappable answer under a message.
class ChatReply {
  const ChatReply({required this.value, required this.label});

  final String value;
  final Map<AppLanguage, String> label;
}

/// A fixed card shown inside a bubble. The AI only chooses the card and fills words.
sealed class ChatCard {
  const ChatCard();
}

class LevelCardData extends ChatCard {
  const LevelCardData({
    required this.level,
    required this.steps,
    required this.healthLock,
  });

  final String level;
  final List<String> steps;
  final bool healthLock;
}

/// The smaller step after missed days. [was] and [now] are step counts.
class MissedDayCardData extends ChatCard {
  const MissedDayCardData({
    required this.was,
    required this.now,
    required this.step,
  });

  final int was;
  final int now;
  final String step;
}

/// The step-up offer. Nothing changes unless the user says yes.
class StepUpCardData extends ChatCard {
  const StepUpCardData({required this.now, required this.bigger});

  final String now;
  final String bigger;
}

/// Shown after "I feel unwell" or "very low": everything is paused.
class HardStopCardData extends ChatCard {
  const HardStopCardData();
}

class LogCardData extends ChatCard {
  const LogCardData({required this.tasks, required this.initialResults});

  final List<String> tasks;
  final Map<int, TaskResult> initialResults;
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
    this.card,
  });

  final int id;
  final bool fromAgent;
  final Map<AppLanguage, String> text;
  final Map<AppLanguage, String>? questionLabel;
  final List<ChatReply> replies;
  final ChatCard? card;

  ChatMessage withoutCard() => ChatMessage(
    id: id,
    fromAgent: fromAgent,
    text: text,
    questionLabel: questionLabel,
    replies: const [],
  );
}

enum OnboardingStep { askGoal, questions, healthCheck, levelPlan }

class ChatState {
  const ChatState({
    required this.messages,
    this.step = OnboardingStep.askGoal,
    this.questionIndex = 0,
    this.answers = const {},
    this.goal,
    this.healthAnswers = const [],
    this.level,
    this.steps = const [],
  });

  final List<ChatMessage> messages;
  final OnboardingStep step;

  /// Index into the plugin's placement questions.
  final int questionIndex;

  /// Placement question id -> chosen value (option id or typed text).
  final Map<String, String> answers;
  final String? goal;

  /// One entry per health question: true means "Yes".
  final List<bool> healthAnswers;

  /// Any "Yes" locks the plan to the gentlest level.
  bool get healthLock => healthAnswers.any((yes) => yes);

  /// The starting level the user agreed to (beginner, building or ready).
  final String? level;

  /// Tomorrow's small steps for the agreed level.
  final List<String> steps;

  ChatState copyWith({
    List<ChatMessage>? messages,
    OnboardingStep? step,
    int? questionIndex,
    Map<String, String>? answers,
    String? goal,
    List<bool>? healthAnswers,
    String? level,
    List<String>? steps,
  }) => ChatState(
    messages: messages ?? this.messages,
    step: step ?? this.step,
    questionIndex: questionIndex ?? this.questionIndex,
    answers: answers ?? this.answers,
    goal: goal ?? this.goal,
    healthAnswers: healthAnswers ?? this.healthAnswers,
    level: level ?? this.level,
    steps: steps ?? this.steps,
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
    ChatCard? card,
  }) => ChatMessage(
    id: _seq++,
    fromAgent: true,
    text: filterOutgoing(text),
    questionLabel: questionLabel,
    replies: replies,
    card: card,
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

  /// Shows the level card with the steps for the current level.
  void _showLevelCard() {
    final level = _placeLevel();
    final steps = state.steps.isEmpty ? dummyStepsFor(level) : state.steps;
    state = state.copyWith(level: level, steps: steps);
    // The newest level card replaces the older one, so only one plan shows.
    state = state.copyWith(
      messages: [
        for (final m in state.messages)
          m.card is LevelCardData ? m.withoutCard() : m,
      ],
    );
    _append(
      _agent(
        textOf('level.intro'),
        replies: [
          ChatReply(value: 'looks_good', label: textOf('level.looks_good')),
          ChatReply(value: 'smaller', label: textOf('level.smaller')),
        ],
        card: LevelCardData(
          level: level,
          steps: steps,
          healthLock: state.healthLock,
        ),
      ),
    );
  }

  String _placeLevel() =>
      placeLevel(fitnessPlugin, state.answers, healthLock: state.healthLock);

  /// "Log how it went": the log card opens in chat with today's results so far.
  void openDailyLog(List<String> tasks, Map<int, TaskResult> results) {
    _append(
      _agent(
        textOf('log.question'),
        card: LogCardData(tasks: tasks, initialResults: results),
      ),
    );
  }

  /// Saves the log card. The reply is the fixed phrase, never AI text.
  void saveDailyLog(
    int messageId,
    Map<int, TaskResult> results,
    Feeling feeling,
  ) {
    ref.read(dayProvider.notifier).saveLog(results, feeling);
    state = state.copyWith(
      messages: [
        for (final m in state.messages) m.id == messageId ? m.withoutCard() : m,
      ],
    );
    _say(textOf('log.saved_reply'));
  }

  void _hardStop() {
    ref.read(dayProvider.notifier).setPaused(true);
    _append(
      _agent(
        textOf('hardstop.care'),
        replies: [
          ChatReply(value: 'keep_paused', label: textOf('hardstop.keep')),
          ChatReply(value: 'resume', label: textOf('hardstop.resume')),
        ],
        card: const HardStopCardData(),
      ),
    );
  }

  void _hardStopReply(ChatReply reply) {
    if (reply.value == 'resume') {
      ref.read(dayProvider.notifier).setPaused(false);
      _say(textOf('hardstop.resume_ack'));
    } else {
      _say(textOf('hardstop.keep_ack'));
    }
  }

  /// The offer after a steady run. Shown only; the plan changes on a yes.
  void openStepUp() {
    if (ref.read(dayProvider).paused) return;
    _append(
      _agent(
        textOf('stepup.reason'),
        card: const StepUpCardData(now: dummyNowStep, bigger: dummyBiggerStep),
      ),
    );
  }

  /// Yes applies the bigger step from tomorrow. Not yet changes nothing.
  void answerStepUp(int messageId, {required bool yes}) {
    final allowed = canStepUp(userSaidYes: yes);
    state = state.copyWith(
      messages: [
        for (final m in state.messages) m.id == messageId ? m.withoutCard() : m,
      ],
    );
    if (allowed) {
      state = state.copyWith(steps: [dummyBiggerStep]);
      _say(textOf('stepup.yes_ack'));
    } else {
      _say(textOf('stepup.not_yet_ack'));
    }
  }

  /// After missed days: the fixed phrase, then one smaller step.
  /// Missed days only ever make the plan smaller. They never reset it.
  void openMissedDays() {
    if (ref.read(dayProvider).paused) return;
    _say(textOf('missed.phrase'));
    _showSmallerStep(
      from: ref.read(dayProvider).tasks.length,
      step: dummySmallestStep,
    );
  }

  void _showSmallerStep({required int from, required String step}) {
    state = state.copyWith(steps: [step]);
    state = state.copyWith(
      messages: [
        for (final m in state.messages)
          m.card is MissedDayCardData ? m.withoutCard() : m,
      ],
    );
    _append(
      _agent(
        textOf('missed.made_smaller'),
        replies: [
          ChatReply(value: 'okay', label: textOf('missed.okay')),
          ChatReply(
            value: 'still_too_much',
            label: textOf('missed.still_much'),
          ),
        ],
        card: MissedDayCardData(was: from, now: 1, step: step),
      ),
    );
  }

  void _missedReply(ChatReply? reply) {
    switch (reply?.value) {
      case 'okay':
        _say(textOf('missed.okay_ack'));
      case 'still_too_much':
        _showSmallerStep(from: 1, step: dummyTinierStep);
      default:
        _say(textOf('chat.noted'));
    }
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

    // The hard stop comes first and applies to every reply after it.
    if (reply == null && isHardStop(text)) {
      _hardStop();
      return;
    }

    if (reply?.value == 'keep_paused' || reply?.value == 'resume') {
      _hardStopReply(reply!);
      return;
    }

    if (ref.read(appProvider).phase != AppPhase.onboarding) {
      if (reply?.value == 'okay' || reply?.value == 'still_too_much') {
        _missedReply(reply);
      } else {
        _say(textOf('chat.noted'));
      }
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
      case OnboardingStep.levelPlan:
        _levelReply(reply);
    }
  }

  void _levelReply(ChatReply? reply) {
    switch (reply?.value) {
      case 'looks_good':
        // Starts today with the agreed steps, then moves to Today.
        // Saving the plan to the database comes later.
        ref.read(dayProvider.notifier).startDay(state.steps);
        ref.read(appProvider.notifier).finishOnboarding();
      case 'smaller':
        // Smaller steps need no extra check: keep only the first step.
        final smaller = state.steps.take(1).toList();
        state = state.copyWith(steps: smaller);
        _say(textOf('level.smaller_ack'));
        _showLevelCard();
      default:
        _say(textOf('chat.noted'));
    }
  }

  /// Called when the health check screen returns its answers (true = Yes).
  void finishHealthCheck(List<bool> answers) {
    if (state.step != OnboardingStep.healthCheck) return;
    state = state.copyWith(
      healthAnswers: answers,
      step: OnboardingStep.levelPlan,
    );
    _showLevelCard();
  }
}

final chatProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);
