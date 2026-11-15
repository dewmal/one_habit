import '../i18n/language.dart';

/// The recipe for a kind of habit. Plain data: a new habit is a new data
/// file, not new screen code. Screens read names, questions and stages from
/// here, so no screen text says the habit's name.
class HabitPlugin {
  const HabitPlugin({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.description,
    required this.levels,
    required this.placementQuestions,
    required this.stages,
    required this.moveOnRule,
    required this.taskGuide,
    required this.cards,
    this.healthCheck,
  });

  final String id;
  final Map<AppLanguage, String> name;
  final String icon;
  final int colorValue;
  final Map<AppLanguage, String> description;
  final List<HabitLevel> levels;
  final List<PlacementQuestion> placementQuestions;
  final List<HabitStage> stages;
  final Map<AppLanguage, String> moveOnRule;

  /// Instructions for the AI on writing tiny daily tasks.
  final String taskGuide;

  /// Card kinds this plugin uses, named by [CardKind].
  final List<CardKind> cards;

  /// Optional safety check. Null means no check.
  final HealthCheck? healthCheck;
}

class HabitLevel {
  const HabitLevel({required this.id, required this.label});

  /// beginner, building or ready. Also the value stored in the habit table.
  final String id;
  final Map<AppLanguage, String> label;
}

class PlacementQuestion {
  const PlacementQuestion({
    required this.id,
    required this.text,
    required this.options,
  });

  final String id;
  final Map<AppLanguage, String> text;
  final List<PlacementOption> options;
}

class PlacementOption {
  const PlacementOption({required this.id, required this.label, this.level});

  final String id;
  final Map<AppLanguage, String> label;

  /// The starting level this answer points to, if it places the user.
  final String? level;
}

class HabitStage {
  const HabitStage({required this.index, required this.name});

  /// 0-based index. Screens show it as "Stage 1 of 5".
  final int index;
  final Map<AppLanguage, String> name;
}

class HealthCheck {
  const HealthCheck({required this.questions});

  final List<Map<AppLanguage, String>> questions;
}

/// The fixed card set built into the app. The AI picks one and fills words.
enum CardKind {
  quickReplies,
  yesNo,
  taskChecklist,
  logCard,
  levelCard,
  stepUpOffer,
  infoCard,
  stageCard,
  progressCard,
  timePicker,
}
