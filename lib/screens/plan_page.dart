import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/day_state.dart';
import '../app/dummy_data.dart';
import '../chat/chat_controller.dart';
import '../app/projects.dart';
import '../components/screen_title_bar.dart';
import '../i18n/language.dart';
import '../plugins/fitness_plugin.dart';
import '../theme/app_theme.dart';

/// Screen 11: view-only list of the stages. Changes happen in chat.
class PlanPage extends ConsumerWidget {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final current = ref.watch(dayProvider.select((d) => d.stageIndex));
    final chat = ref.watch(chatProvider);
    final level = fitnessPlugin.levels.firstWhere(
      (l) => l.id == (chat.level ?? 'beginner'),
      orElse: () => fitnessPlugin.levels.first,
    );
    final goal = chat.goal ?? resolve(dummyGoal, language);
    final stages = fitnessPlugin.stages;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          ScreenTitleBar(
            title: tr('plan.title', language),
            subtitle:
                '${ref.watch(projectsProvider).current.name} · ${resolve(level.label, language)}',
          ),
          const SizedBox(height: AppSpacing.gap16),
          for (final stage in stages) ...[
            _StageRow(
              number: stage.index + 1,
              name: resolve(stage.name, language),
              current: stage.index == current,
              rule: resolve(fitnessPlugin.moveOnRule, language),
              youAreHere: tr('plan.here', language),
              goalLine: stage.index == stages.length - 1
                  ? resolve(textOf('plan.goal', {'goal': goal}), language)
                  : null,
            ),
            const SizedBox(height: AppSpacing.gap10),
          ],
          const SizedBox(height: AppSpacing.gap8),
          Text(tr('plan.note', language), style: AppText.bodyMuted),
        ],
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.number,
    required this.name,
    required this.current,
    required this.rule,
    required this.youAreHere,
    this.goalLine,
  });

  final int number;
  final String name;
  final bool current;
  final String rule;
  final String youAreHere;
  final String? goalLine;

  @override
  Widget build(BuildContext context) {
    final ink = current ? AppColors.bg : AppColors.text;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.gap16),
      decoration: BoxDecoration(
        gradient: current ? sunsetGradient : null,
        color: current ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: current ? AppColors.bg : AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadii.smallButton),
            ),
            child: Text(
              '$number',
              style: AppText.cardTitle.copyWith(color: AppColors.text),
            ),
          ),
          const SizedBox(width: AppSpacing.gap16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (current)
                  Text(
                    youAreHere,
                    style: AppText.smallLabel.copyWith(color: AppColors.bg),
                  ),
                Text(name, style: AppText.cardTitle.copyWith(color: ink)),
                if (current) ...[
                  const SizedBox(height: AppSpacing.gap8),
                  Text(rule, style: AppText.body.copyWith(color: AppColors.bg)),
                ],
                if (goalLine != null) ...[
                  const SizedBox(height: 4),
                  Text(goalLine!, style: AppText.bodyMuted),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
