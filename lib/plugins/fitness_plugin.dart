import '../i18n/language.dart';
import 'habit_plugin.dart';

/// The Fitness plugin as data. Placeholder text is marked "(placeholder)"
/// until the content is written (UI guide page 1).
const fitnessPlugin = HabitPlugin(
  id: 'fitness',
  name: {AppLanguage.en: 'Fitness', AppLanguage.si: 'Fitness'},
  icon: 'dumbbell',
  colorValue: 0xFFF2646C,
  description: {
    AppLanguage.en: 'Go to the gym regularly, one small step at a time.',
    AppLanguage.si: 'Go to the gym regularly, one small step at a time.',
  },
  levels: [
    HabitLevel(id: 'beginner', label: {AppLanguage.en: 'Beginner', AppLanguage.si: 'Beginner'}),
    HabitLevel(id: 'building', label: {AppLanguage.en: 'Building', AppLanguage.si: 'Building'}),
    HabitLevel(id: 'ready', label: {AppLanguage.en: 'Ready', AppLanguage.si: 'Ready'}),
  ],
  placementQuestions: [
    PlacementQuestion(
      id: 'q1',
      text: {AppLanguage.en: 'How often have you trained in the last month? (placeholder)', AppLanguage.si: 'placeholder'},
    ),
  ],
  stages: [
    HabitStage(index: 0, name: {AppLanguage.en: 'Stage 1 name (placeholder)', AppLanguage.si: 'placeholder'}),
    HabitStage(index: 1, name: {AppLanguage.en: 'Stage 2 name (placeholder)', AppLanguage.si: 'placeholder'}),
    HabitStage(index: 2, name: {AppLanguage.en: 'Stage 3 name (placeholder)', AppLanguage.si: 'placeholder'}),
    HabitStage(index: 3, name: {AppLanguage.en: 'Stage 4 name (placeholder)', AppLanguage.si: 'placeholder'}),
    HabitStage(index: 4, name: {AppLanguage.en: 'Stage 5 name (placeholder)', AppLanguage.si: 'placeholder'}),
  ],
  moveOnRule: {
    AppLanguage.en: 'Move on only when you say yes. (placeholder rule)',
    AppLanguage.si: 'placeholder',
  },
  taskGuide: 'Write 1 to 3 tiny tasks for the current stage. Never bigger than the stage allows.',
  cards: [
    CardKind.quickReplies,
    CardKind.yesNo,
    CardKind.taskChecklist,
    CardKind.logCard,
    CardKind.levelCard,
    CardKind.stepUpOffer,
    CardKind.infoCard,
  ],
  healthCheck: HealthCheck(
    questions: [
      {AppLanguage.en: 'Health question 1 (placeholder)?', AppLanguage.si: 'placeholder'},
      {AppLanguage.en: 'Health question 2 (placeholder)?', AppLanguage.si: 'placeholder'},
      {AppLanguage.en: 'Health question 3 (placeholder)?', AppLanguage.si: 'placeholder'},
    ],
  ),
);
