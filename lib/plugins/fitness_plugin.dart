import '../i18n/language.dart';
import 'habit_plugin.dart';

/// The Fitness plugin as data. Stage names and health questions are still
/// placeholders (UI guide page 1). The placement questions after the first
/// are drafts; replace the wording when approved.
const fitnessPlugin = HabitPlugin(
  id: 'fitness',
  name: {AppLanguage.en: 'Fitness', AppLanguage.si: 'Fitness'},
  projectName: {AppLanguage.en: 'Improve my fitness'},
  icon: 'dumbbell',
  colorValue: 0xFFF2646C,
  description: {
    AppLanguage.en: 'Go to the gym regularly, one small step at a time.',
  },
  levels: [
    HabitLevel(id: 'beginner', label: {AppLanguage.en: 'Beginner'}),
    HabitLevel(id: 'building', label: {AppLanguage.en: 'Building'}),
    HabitLevel(id: 'ready', label: {AppLanguage.en: 'Ready'}),
  ],
  placementQuestions: [
    PlacementQuestion(
      id: 'exercise_now',
      text: {AppLanguage.en: 'How often do you exercise now?'},
      options: [
        PlacementOption(
          id: 'none',
          label: {AppLanguage.en: 'Not at all'},
          level: 'beginner',
        ),
        PlacementOption(
          id: 'weekly',
          label: {AppLanguage.en: 'Once or twice a week'},
          level: 'building',
        ),
        PlacementOption(
          id: 'most',
          label: {AppLanguage.en: 'Most days'},
          level: 'ready',
        ),
      ],
    ),
    PlacementQuestion(
      id: 'session_length',
      text: {AppLanguage.en: 'How long can you keep moving in one go?'},
      options: [
        PlacementOption(id: 'short', label: {AppLanguage.en: '5 minutes'}),
        PlacementOption(id: 'medium', label: {AppLanguage.en: '15 minutes'}),
        PlacementOption(
          id: 'long',
          label: {AppLanguage.en: '30 minutes or more'},
        ),
      ],
    ),
    PlacementQuestion(
      id: 'best_time',
      text: {AppLanguage.en: 'What time of day suits you best?'},
      options: [
        PlacementOption(id: 'morning', label: {AppLanguage.en: 'Morning'}),
        PlacementOption(id: 'afternoon', label: {AppLanguage.en: 'Afternoon'}),
        PlacementOption(id: 'evening', label: {AppLanguage.en: 'Evening'}),
      ],
    ),
    PlacementQuestion(
      id: 'access',
      text: {AppLanguage.en: 'Can you reach a gym easily?'},
      options: [
        PlacementOption(id: 'yes', label: {AppLanguage.en: 'Yes'}),
        PlacementOption(id: 'no', label: {AppLanguage.en: 'No'}),
      ],
    ),
  ],
  stages: [
    HabitStage(index: 0, name: {AppLanguage.en: 'Stage 1 name (placeholder)'}),
    HabitStage(index: 1, name: {AppLanguage.en: 'Stage 2 name (placeholder)'}),
    HabitStage(index: 2, name: {AppLanguage.en: 'Stage 3 name (placeholder)'}),
    HabitStage(index: 3, name: {AppLanguage.en: 'Stage 4 name (placeholder)'}),
    HabitStage(index: 4, name: {AppLanguage.en: 'Stage 5 name (placeholder)'}),
  ],
  moveOnRule: {
    AppLanguage.en: 'Move on only when you say yes. (placeholder rule)',
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
      {AppLanguage.en: 'Health question 1 (placeholder)?'},
      {
        AppLanguage.en: 'Health question 2 (placeholder): has a doctor told you to be careful with exercise?',
      },
      {AppLanguage.en: 'Health question 3 (placeholder)?'},
      {AppLanguage.en: 'Health question 4 (placeholder)?'},
    ],
  ),
);
