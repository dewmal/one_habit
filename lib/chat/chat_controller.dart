import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/connection_status.dart' show gatewayUrl;
import '../ai/gateway_llm_client.dart';
import '../ai/llm_client.dart';
import '../app/app_state.dart';
import '../app/day_state.dart';
import '../app/projects.dart';
import '../app/rules.dart';
import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../data/startup.dart';
import '../i18n/language.dart';
import '../plugins/fitness_plugin.dart';
import '../plugins/habit_plugin.dart';
import 'chat_message.dart';
import 'history.dart';

export 'chat_message.dart';

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
/// Every message is saved to the database first, then shown.
class ChatController extends Notifier<ChatState> {
  /// The last queued user message. Each one waits for the one before it.
  Future<void> _turn = Future.value();

  /// Database writes run one after another, so ids and screen order match.
  Future<void> _queue = Future.value();

  AppDatabase get _db => ref.read(databaseProvider);

  int get _chatId => ref.read(projectsProvider).current.generalChat.id;

  int get _habitId => ref.read(projectsProvider).current.id;

  @override
  ChatState build() {
    final start = ref.watch(startupProvider);
    if (start.habits.isEmpty || start.habits.first['level'] == null) {
      // No finished habit: onboarding starts from the top.
      return const ChatState(messages: []);
    }
    final habit = start.habits.first;
    final safety = habit['safety_result'] as String?;
    return ChatState(
      messages: [for (final r in start.generalMessages) messageFromRow(r)],
      step: OnboardingStep.levelPlan,
      goal: habit['goal'] as String?,
      level: habit['level'] as String?,
      healthAnswers: safety == null ? const [] : [safety == 'gentle'],
    );
  }

  Future<T> _enqueue<T>(Future<T> Function() job) {
    final result = _queue.then((_) => job());
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// Starts onboarding from the top: the General chat is cleared and the
  /// greeting is saved.
  Future<void> beginOnboarding() async {
    await _enqueue(() => _db.deleteChat(_chatId));
    state = const ChatState(messages: []);
    await _sayKey('chat.greeting');
  }

  /// Deletes the messages of the General chat. The goal, level and plan stay.
  Future<void> clearMessages() async {
    await _enqueue(() => _db.deleteChat(_chatId));
    state = state.copyWith(messages: const []);
  }

  /// Clears the chat and everything learned in onboarding.
  Future<void> reset() async {
    await clearMessages();
    state = const ChatState(messages: []);
  }

  /// Deletes the habit answers: goal, placement, health check and level.
  Future<void> clearHabit() async {
    await _db.updateHabit(_habitId, {
      'goal': null,
      'level': null,
      'safety_result': null,
    });
    state = ChatState(messages: state.messages);
  }

  /// Deletes the steps the plan was built from.
  void clearSteps() => state = state.copyWith(steps: const []);

  /// Saves one message, then shows it. Returns the row id.
  Future<int> _save(
    String role, {
    String text = '',
    String? textKey,
    ChatCard? card,
  }) => _enqueue(() async {
    final kind = card != null ? 'card' : (textKey != null ? 'fixed' : 'text');
    final cardData = card == null ? null : jsonEncode(card.toJson());
    final id = await _db.addMessage(
      _chatId,
      role,
      kind: kind,
      text: text,
      textKey: textKey,
      cardType: card?.type,
      cardData: cardData,
    );
    state = state.copyWith(
      messages: [
        ...state.messages,
        messageFromRow({
          'id': id,
          'role': role,
          'kind': kind,
          'text': text,
          'text_key': textKey,
          'card_type': card?.type,
          'card_data': cardData,
          'card_answer': null,
          'status': 'sent',
        }),
      ],
    );
    return id;
  });

  /// An approved phrase, saved by its key.
  Future<void> _sayKey(String key) => _save('assistant', textKey: key);

  /// AI text. The rules engine has the final say: blocked wording is never
  /// saved, a calm fixed phrase is saved instead.
  Future<void> _sayAi(String text) => isBlocked(text)
      ? _sayKey('chat.safe_fallback')
      : _save('assistant', text: text);

  /// Saves the user's tap or answer on a card and hides what was answered.
  Future<void> _answer(int messageId, String answer) => _enqueue(() async {
    await _db.answerCard(messageId, answer);
    state = state.copyWith(
      messages: [
        for (final m in state.messages)
          m.id == messageId ? m.answered(answer) : m,
      ],
    );
  });

  /// The newest message that still waits for a tap on its quick replies.
  ChatMessage? get _openReplies {
    for (final m in state.messages.reversed) {
      if (m.fromAgent && m.replies.isNotEmpty) return m;
    }
    return null;
  }

  int get _placementCount => fitnessPlugin.placementQuestions.length;

  Future<void> _askQuestion(int index) =>
      _save('assistant', card: QuestionCardData(index: index));

  /// Shows the level card with the steps for the current level. The AI writes
  /// the tiny steps through the gateway. If that fails, the fixed steps for the
  /// level are shown, so the plan never waits on the network.
  Future<void> _showLevelCard() async {
    final level = _placeLevel();
    final steps = state.steps.isEmpty ? await _writeSteps(level) : state.steps;
    state = state.copyWith(level: level, steps: steps);
    // The newest level card replaces the older one, so only one plan shows.
    for (final m in state.messages.toList()) {
      if (m.card is LevelCardData) await _answer(m.id, 'replaced');
    }
    await _save(
      'assistant',
      card: LevelCardData(
        level: level,
        steps: steps,
        healthLock: state.healthLock,
      ),
    );
  }

  String _placeLevel() =>
      placeLevel(fitnessPlugin, state.answers, healthLock: state.healthLock);

  /// "Log how it went": the log card opens in chat with today's results so far.
  Future<void> openDailyLog(List<String> tasks, Map<int, TaskResult> results) =>
      _save(
        'assistant',
        card: LogCardData(tasks: tasks, initialResults: results),
      );

  /// Saves the log card. The reply is the fixed phrase, never AI text.
  Future<void> saveDailyLog(
    int messageId,
    Map<int, TaskResult> results,
    Feeling feeling,
  ) async {
    ref.read(dayProvider.notifier).saveLog(results, feeling);
    await _answer(messageId, 'saved');
    await _sayKey('log.saved_reply');
  }

  Future<void> _hardStop() async {
    ref.read(dayProvider.notifier).setPaused(true);
    await _save('assistant', card: const HardStopCardData());
  }

  Future<void> _hardStopReply(ChatReply reply) async {
    if (reply.value == 'resume') {
      ref.read(dayProvider.notifier).setPaused(false);
      await _sayKey('hardstop.resume_ack');
    } else {
      await _sayKey('hardstop.keep_ack');
    }
  }

  /// The steps of the plan now: today's tasks, or the ones just agreed.
  List<String> get _currentSteps {
    final tasks = ref.read(dayProvider).tasks;
    if (tasks.isNotEmpty) return tasks;
    return state.steps.isNotEmpty
        ? state.steps
        : fitnessPlugin.fallbackStepsFor(state.level ?? 'beginner');
  }

  /// The offer after a steady run. Shown only; the plan changes on a yes.
  Future<void> openStepUp() async {
    if (ref.read(dayProvider).paused) return;
    final now = _currentSteps.last;
    await _save(
      'assistant',
      card: StepUpCardData(now: now, bigger: fitnessPlugin.biggerStep(now)),
    );
  }

  /// Yes applies the bigger step from tomorrow. Not yet changes nothing.
  Future<void> answerStepUp(int messageId, {required bool yes}) async {
    final allowed = canStepUp(userSaidYes: yes);
    await _answer(messageId, yes ? 'yes' : 'not_yet');
    if (allowed) {
      // The bigger step is saved in the plan and starts tomorrow.
      final bigger = fitnessPlugin.biggerStep(_currentSteps.last);
      state = state.copyWith(steps: [bigger]);
      ref.read(dayProvider.notifier).planTasks([bigger]);
      await _sayKey('stepup.yes_ack');
    } else {
      await _sayKey('stepup.not_yet_ack');
    }
  }

  /// After missed days: the fixed phrase, then one smaller step.
  /// Missed days only ever make the plan smaller. They never reset it.
  Future<void> openMissedDays() async {
    if (ref.read(dayProvider).paused) return;
    await _sayKey('missed.phrase');
    await _showSmallerStep(
      from: ref.read(dayProvider).tasks.length,
      step: fitnessPlugin.smallerStep(_currentSteps.first),
    );
  }

  Future<void> _showSmallerStep({
    required int from,
    required String step,
  }) async {
    state = state.copyWith(steps: [step]);
    ref.read(dayProvider.notifier).planTasks([step]);
    for (final m in state.messages.toList()) {
      if (m.card is MissedDayCardData) await _answer(m.id, 'replaced');
    }
    await _save(
      'assistant',
      card: MissedDayCardData(was: from, now: 1, step: step),
    );
  }

  Future<void> _missedReply(ChatReply? reply) async {
    switch (reply?.value) {
      case 'okay':
        await _sayKey('missed.okay_ack');
      case 'still_too_much':
        await _showSmallerStep(
          from: 1,
          step: fitnessPlugin.smallerStep(state.steps.first),
        );
      default:
        await _sayKey('chat.noted');
    }
  }

  /// Asks the AI for a coach reply to the user's message [userId]. The rules
  /// engine still has the final say. If the call fails, the user's message is
  /// marked failed and shows "Try again". No error bubble is saved.
  Future<void> _coachReply(int userId) async {
    AgentSuggestion? suggestion;
    String? failure;
    try {
      suggestion = await askCoach(
        ref.read(llmProvider),
        language: _languageName(),
        summary: _context(),
        // Only the last 10 saved text messages go to the gateway.
        rows: await _db.recentTextMessages(_chatId),
      );
    } on AiException catch (e) {
      failure = e.code;
    } catch (_) {
      failure = 'no_connection';
    }

    // A hard stop that came in while waiting wins: nothing more is shown.
    if (ref.read(dayProvider).paused) return;

    if (suggestion == null) {
      await _markFailed(userId, true);
      // Do not retry in a loop: a rate limit gets the fixed short-break phrase.
      if (failure == 'rate_limited') await _sayKey('chat.rate_limited');
      return;
    }
    await _sayAi(suggestion.text);

    // The AI may only suggest. The step-up card asks the user first.
    if (suggestion.wantsBigger) await openStepUp();
  }

  Future<void> _markFailed(int messageId, bool failed) => _enqueue(() async {
    await _db.setStatus(messageId, failed ? 'failed' : 'sent');
    state = state.copyWith(
      messages: [
        for (final m in state.messages)
          m.id == messageId ? m.withFailed(failed) : m,
      ],
    );
  });

  /// "Try again" on a failed message: the same message is sent again. No
  /// second copy is made.
  Future<void> retry(int messageId) async {
    await _markFailed(messageId, false);
    _turn = _turn.then((_) => _coachReply(messageId));
  }

  /// The short context line sent with every request. Never health answers,
  /// the name or the daily log.
  String _context() =>
      'Goal: ${state.goal ?? ''}. Level: ${state.level ?? ''}.'
      '${state.healthLock ? ' Keep very gentle.' : ''}';

  /// Asks the AI for today's and tomorrow's tiny steps. Blocked wording is
  /// dropped. Any failure falls back to the fixed steps for the level.
  Future<List<String>> _writeSteps(String level) async {
    try {
      final tasks = await ref
          .read(llmProvider)
          .writeTasks(
            language: _languageName(),
            level: level,
            taskGuide: fitnessPlugin.taskGuide,
          );
      final safe = [
        for (final t in tasks)
          if (!isBlocked(t)) t,
      ];
      if (safe.isNotEmpty) return safe;
    } catch (_) {
      // The plan never waits on the network: the fixed steps are used.
    }
    return fitnessPlugin.fallbackStepsFor(level);
  }

  String _languageName() =>
      ref.read(languageProvider) == AppLanguage.si ? 'Sinhala' : 'English';

  /// The user typed text, or tapped a quick reply (pass [reply]).
  void send(String raw, {ChatReply? reply}) {
    final text = raw.trim();
    if (text.isEmpty && reply == null) return;

    // Save first, then show.
    final label = reply == null ? text : (reply.label[AppLanguage.en] ?? '');
    final saved = _save('user', text: label);
    // The id is known once the message is saved; _respond needs it.

    // The hard stop comes first and applies to every reply after it.
    if (reply == null && isHardStop(text)) {
      _hardStop();
      return;
    }

    if (reply?.value == 'keep_paused' || reply?.value == 'resume') {
      final open = _openReplies;
      if (open != null) _answer(open.id, reply!.value);
      _hardStopReply(reply!);
      return;
    }

    // The answer is saved on the card that asked. A typed line only answers
    // a placement question.
    final open = _openReplies;
    if (open != null && (reply != null || open.card is QuestionCardData)) {
      _answer(open.id, reply?.value ?? text);
    }

    // Messages are answered one at a time, in order. The next screen is built
    // only after the gateway has answered.
    _turn = _turn.then((_) async {
      await _respond(await saved, text, reply);
    });
  }

  /// One user message: ask the gateway first, then build the next screen.
  Future<void> _respond(int userId, String text, ChatReply? reply) async {
    await _coachReply(userId);
    if (ref.read(dayProvider).paused) return;

    if (ref.read(appProvider).phase != AppPhase.onboarding) {
      if (reply?.value == 'okay' || reply?.value == 'still_too_much') {
        await _missedReply(reply);
      }
      return;
    }

    switch (state.step) {
      case OnboardingStep.askGoal:
        state = state.copyWith(goal: text, step: OnboardingStep.questions);
        await _db.updateHabit(_habitId, {'goal': text});
        await _sayKey('chat.good_goal');
        await _askQuestion(0);
      case OnboardingStep.questions:
        final question = fitnessPlugin.placementQuestions[state.questionIndex];
        final answers = {...state.answers, question.id: reply?.value ?? text};
        final next = state.questionIndex + 1;
        if (next < _placementCount) {
          state = state.copyWith(answers: answers, questionIndex: next);
          await _askQuestion(next);
        } else {
          state = state.copyWith(
            answers: answers,
            step: OnboardingStep.healthCheck,
          );
          await _sayKey('chat.health_next');
        }
      case OnboardingStep.healthCheck:
        break;
      case OnboardingStep.levelPlan:
        await _levelReply(reply);
    }
  }

  Future<void> _levelReply(ChatReply? reply) async {
    switch (reply?.value) {
      case 'looks_good':
        // Starts today with the agreed steps, then moves to Today. The level
        // is saved on the habit: that is what marks onboarding as finished.
        await _db.updateHabit(_habitId, {'level': state.level});
        ref.read(dayProvider.notifier).startDay(state.steps);
        ref.read(appProvider.notifier).finishOnboarding();
      case 'smaller':
        // Smaller steps need no extra check: keep only the first step.
        final smaller = state.steps.take(1).toList();
        state = state.copyWith(steps: smaller);
        await _sayKey('level.smaller_ack');
        await _showLevelCard();
      default:
        await _sayKey('chat.noted');
    }
  }

  /// Called when the health check screen returns its answers (true = Yes).
  Future<void> finishHealthCheck(List<bool> answers) async {
    if (state.step != OnboardingStep.healthCheck) return;
    state = state.copyWith(
      healthAnswers: answers,
      step: OnboardingStep.levelPlan,
    );
    // Only the result is saved, never the answers.
    await _db.updateHabit(_habitId, {
      'safety_result': state.healthLock ? 'gentle' : 'normal',
    });
    await _showLevelCard();
  }
}

final chatProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);

/// The gateway URL comes from the build: --dart-define=GATEWAY_URL=https://...
/// Every AI call goes to the gateway. With no URL, the calls fail with
/// no_connection and the calm message shows; nothing is faked.

final llmProvider = Provider<LlmClient>(
  (ref) => GatewayLlmClient(gatewayUrl: gatewayUrl),
);
