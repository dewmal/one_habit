import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chat/chat_controller.dart';
import '../app/day_state.dart';
import '../app/projects.dart';
import '../components/screen_title_bar.dart';
import '../components/main_button.dart';
import '../components/stage_card.dart';
import '../components/task_tile.dart';
import '../i18n/language.dart';
import '../plugins/fitness_plugin.dart';
import '../theme/app_theme.dart';

/// Screen 10: only today's tasks. No streaks, scores or tomorrow's tasks.
class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final day = ref.watch(dayProvider);
    final controller = ref.read(dayProvider.notifier);
    final stage = fitnessPlugin.stages[day.stageIndex];
    final count = day.tasks.length;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenTitleBar(
              title: tr('today.title', language),
              subtitle: ref.watch(projectsProvider).current.name,
            ),
            if (day.offline) ...[
              const SizedBox(height: AppSpacing.gap12),
              _OfflineBanner(text: tr('today.offline', language)),
            ],
            const SizedBox(height: AppSpacing.gap16),
            StageCard(
              stageLabel: tr('today.stage_of', language)
                  .replaceAll('{n}', '${day.stageIndex + 1}')
                  .replaceAll('{total}', '${fitnessPlugin.stages.length}'),
              name: resolve(stage.name, language),
              line: resolve(
                textOf('today.stage_line', {'n': '$count'}),
                language,
              ),
            ),
            const SizedBox(height: AppSpacing.gap16),
            Expanded(
              child: ListView.separated(
                itemCount: count,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.gap10),
                itemBuilder: (context, index) => TaskTile(
                  text: day.tasks[index],
                  done: day.results[index] == TaskResult.done,
                  onToggle: () => controller.toggleTask(index),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.gap16),
            MainButton(
              label: tr('today.log_button', language),
              onPressed: () {
                ref
                    .read(chatProvider.notifier)
                    .openDailyLog(day.tasks, day.results);
                ref.read(projectsProvider.notifier).openGeneral();
              },
            ),
            const SizedBox(height: AppSpacing.gap16),
          ],
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gap12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.row),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: AppColors.sunsetYellow, size: 20),
          const SizedBox(width: AppSpacing.gap8),
          Expanded(child: Text(text, style: AppText.bodyMuted)),
        ],
      ),
    );
  }
}
