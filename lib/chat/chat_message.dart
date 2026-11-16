import 'dart:convert';

import '../app/day_state.dart';
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

  /// The value of `chat_message.card_type`.
  String get type;

  /// The card's values, saved as JSON in `chat_message.card_data`.
  Map<String, Object?> toJson();
}

/// A placement question. The words come from the plugin, by [index].
class QuestionCardData extends ChatCard {
  const QuestionCardData({required this.index});

  final int index;

  @override
  String get type => 'question';

  @override
  Map<String, Object?> toJson() => {'index': index};
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

  @override
  String get type => 'level';

  @override
  Map<String, Object?> toJson() => {
    'level': level,
    'steps': steps,
    'healthLock': healthLock,
  };
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

  @override
  String get type => 'missed_day';

  @override
  Map<String, Object?> toJson() => {'was': was, 'now': now, 'step': step};
}

/// The step-up offer. Nothing changes unless the user says yes.
class StepUpCardData extends ChatCard {
  const StepUpCardData({required this.now, required this.bigger});

  final String now;
  final String bigger;

  @override
  String get type => 'step_up';

  @override
  Map<String, Object?> toJson() => {'now': now, 'bigger': bigger};
}

/// Shown after "I feel unwell" or "very low": everything is paused.
class HardStopCardData extends ChatCard {
  const HardStopCardData();

  @override
  String get type => 'hard_stop';

  @override
  Map<String, Object?> toJson() => {};
}

class LogCardData extends ChatCard {
  const LogCardData({required this.tasks, required this.initialResults});

  final List<String> tasks;
  final Map<int, TaskResult> initialResults;

  @override
  String get type => 'log';

  @override
  Map<String, Object?> toJson() => {
    'tasks': tasks,
    'initial': {
      for (final e in initialResults.entries) '${e.key}': e.value.name,
    },
  };
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
    this.failed = false,
  });

  /// The row id of the chat_message table.
  final int id;
  final bool fromAgent;
  final Map<AppLanguage, String> text;
  final Map<AppLanguage, String>? questionLabel;
  final List<ChatReply> replies;
  final ChatCard? card;

  /// A user message that could not be answered. The bubble shows "Try again".
  final bool failed;

  /// What the user tapped on the card. Hides the quick replies, and for the
  /// step-up and log cards, the card too.
  ChatMessage answered(String answer) {
    final gone =
        answer == 'replaced' || card is StepUpCardData || card is LogCardData;
    return ChatMessage(
      id: id,
      fromAgent: fromAgent,
      text: text,
      questionLabel: questionLabel,
      replies: const [],
      card: gone ? null : card,
    );
  }

  ChatMessage withFailed(bool value) =>
      ChatMessage(id: id, fromAgent: fromAgent, text: text, failed: value);
}

Map<AppLanguage, String> _same(String text) => {
  AppLanguage.en: text,
  AppLanguage.si: text,
};

/// Builds the bubble for one chat_message row. The same function is used for
/// a message just saved and for one loaded later, so they always look alike.
ChatMessage messageFromRow(Map<String, Object?> row) {
  final id = row['id'] as int;
  final fromAgent = row['role'] == 'assistant';
  final failed = row['status'] == 'failed';
  switch (row['kind']) {
    case 'fixed':
      return ChatMessage(
        id: id,
        fromAgent: fromAgent,
        text: textOf(row['text_key'] as String),
      );
    case 'card':
      final data = jsonDecode(
        (row['card_data'] as String?) ?? '{}',
      ) as Map<String, dynamic>;
      final message = _cardMessage(id, row['card_type'] as String, data);
      final answer = (row['card_answer'] as String?) ?? '';
      return answer.isEmpty ? message : message.answered(answer);
    default:
      return ChatMessage(
        id: id,
        fromAgent: fromAgent,
        text: _same((row['text'] as String?) ?? ''),
        failed: failed,
      );
  }
}

ChatMessage _cardMessage(int id, String type, Map<String, dynamic> data) {
  switch (type) {
    case 'question':
      final index = data['index'] as int;
      final question = fitnessPlugin.placementQuestions[index];
      return ChatMessage(
        id: id,
        fromAgent: true,
        text: question.text,
        questionLabel: textOf('chat.question_label', {
          'n': '${index + 2}',
          'total': '${fitnessPlugin.placementQuestions.length + 1}',
        }),
        replies: [
          for (final o in question.options)
            ChatReply(value: o.id, label: o.label),
        ],
        card: QuestionCardData(index: index),
      );
    case 'level':
      return ChatMessage(
        id: id,
        fromAgent: true,
        text: textOf('level.intro'),
        replies: [
          ChatReply(value: 'looks_good', label: textOf('level.looks_good')),
          ChatReply(value: 'smaller', label: textOf('level.smaller')),
        ],
        card: LevelCardData(
          level: data['level'] as String,
          steps: List<String>.from(data['steps'] as List),
          healthLock: data['healthLock'] as bool,
        ),
      );
    case 'missed_day':
      return ChatMessage(
        id: id,
        fromAgent: true,
        text: textOf('missed.made_smaller'),
        replies: [
          ChatReply(value: 'okay', label: textOf('missed.okay')),
          ChatReply(
            value: 'still_too_much',
            label: textOf('missed.still_much'),
          ),
        ],
        card: MissedDayCardData(
          was: data['was'] as int,
          now: data['now'] as int,
          step: data['step'] as String,
        ),
      );
    case 'step_up':
      return ChatMessage(
        id: id,
        fromAgent: true,
        text: textOf('stepup.reason'),
        card: StepUpCardData(
          now: data['now'] as String,
          bigger: data['bigger'] as String,
        ),
      );
    case 'hard_stop':
      return ChatMessage(
        id: id,
        fromAgent: true,
        text: textOf('hardstop.care'),
        replies: [
          ChatReply(value: 'keep_paused', label: textOf('hardstop.keep')),
          ChatReply(value: 'resume', label: textOf('hardstop.resume')),
        ],
        card: const HardStopCardData(),
      );
    default:
      final initial = (data['initial'] as Map<String, dynamic>?) ?? const {};
      return ChatMessage(
        id: id,
        fromAgent: true,
        text: textOf('log.question'),
        card: LogCardData(
          tasks: List<String>.from((data['tasks'] as List?) ?? const []),
          initialResults: {
            for (final e in initial.entries)
              int.parse(e.key): TaskResult.values.byName(e.value as String),
          },
        ),
      );
  }
}
