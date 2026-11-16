import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_state.dart';
import '../app/day_state.dart';
import '../app/settings_state.dart';
import '../chat/chat_controller.dart';
import '../i18n/language.dart';
import '../theme/app_theme.dart';

enum DataSection { about, habit, plan, log, chat }

/// Screen 14: view or delete each kind of saved data, or everything at once.
class MyDataPage extends ConsumerWidget {
  const MyDataPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton.filled(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.text,
                    ),
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: AppSpacing.gap12),
                  Text(
                    tr('data.title', language),
                    style: AppText.screenTitleSmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.gap12),
              Text(tr('data.intro', language), style: AppText.bodyMuted),
              const SizedBox(height: AppSpacing.gap16),
              Expanded(
                child: ListView(
                  children: [
                    for (final section in DataSection.values) ...[
                      _SectionRow(
                        key: ValueKey('data-${section.name}'),
                        section: section,
                      ),
                      const SizedBox(height: AppSpacing.gap10),
                    ],
                  ],
                ),
              ),
              Text(
                tr('data.delete_means', language),
                textAlign: TextAlign.center,
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: AppSpacing.gap12),
              SizedBox(
                height: AppSpacing.mainButtonHeight,
                child: FilledButton(
                  onPressed: () => _confirmDeleteAll(context, ref),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    foregroundColor: AppColors.bg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.mainButton),
                    ),
                    textStyle: AppText.cardTitle,
                  ),
                  child: Text(tr('data.delete_all', language)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final language = ref.read(languageProvider);
    final ok = await _ask(
      context,
      language,
      title: tr('data.confirm_all_title', language),
      body: tr('data.confirm_all_body', language),
    );
    if (!ok || !context.mounted) return;

    ref.read(settingsProvider.notifier).reset();
    ref.read(chatProvider.notifier).reset();
    ref.read(dayProvider.notifier).clearAll();
    // Close My data and Settings, then go back to the first screen.
    Navigator.of(context).popUntil((route) => route.isFirst);
    ref.read(appProvider.notifier).resetToWelcome();
  }
}

class _SectionRow extends ConsumerWidget {
  const _SectionRow({super.key, required this.section});

  final DataSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final (titleKey, descKey) = switch (section) {
      DataSection.about => ('data.about', 'data.about_desc'),
      DataSection.habit => ('data.habit', 'data.habit_desc'),
      DataSection.plan => ('data.plan', 'data.plan_desc'),
      DataSection.log => ('data.log', 'data.log_desc'),
      DataSection.chat => ('data.chat', 'data.chat_desc'),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.gap16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.row),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr(titleKey, language), style: AppText.cardTitle),
          const SizedBox(height: 2),
          Text(tr(descKey, language), style: AppText.bodyMuted),
          const SizedBox(height: AppSpacing.gap12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _view(context, ref, language),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.text,
                  backgroundColor: AppColors.surfaceRaised,
                  minimumSize: const Size(
                    AppSpacing.minTouch,
                    AppSpacing.minTouch,
                  ),
                ),
                child: Text(tr('data.view', language)),
              ),
              const SizedBox(width: AppSpacing.gap8),
              OutlinedButton(
                onPressed: () => _delete(context, ref, language),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                  minimumSize: const Size(
                    AppSpacing.minTouch,
                    AppSpacing.minTouch,
                  ),
                  side: const BorderSide(
                    color: AppColors.coralBright,
                    width: 2,
                  ),
                ),
                child: Text(tr('data.delete', language)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _lines(WidgetRef ref, AppLanguage language) {
    switch (section) {
      case DataSection.about:
        final s = ref.read(settingsProvider);
        return [
          'Language: ${language.name}',
          'Most reminders a day: ${s.dailyLimit}',
          'Morning: ${formatTime(s.morning)}',
          'Evening: ${formatTime(s.evening)}',
          'Quiet hours: ${formatTime(s.quietStart)} to ${formatTime(s.quietEnd)}',
        ];
      case DataSection.habit:
        final c = ref.read(chatProvider);
        return [
          'Goal: ${c.goal ?? '-'}',
          'Level: ${c.level ?? '-'}',
          'Health check: ${c.healthAnswers.isEmpty
              ? '-'
              : c.healthLock
              ? 'Yes, gentle plan'
              : 'No'}',
        ];
      case DataSection.plan:
        final d = ref.read(dayProvider);
        return [
          'Stage: ${d.stageIndex + 1}',
          for (final t in d.tasks) 'Step: $t',
        ];
      case DataSection.log:
        final d = ref.read(dayProvider);
        return [
          for (final e in d.history)
            '${e.date.day}/${e.date.month}: ${e.results.length} result(s)${e.feeling == null ? '' : ', ${e.feeling!.name}'}',
        ];
      case DataSection.chat:
        final c = ref.read(chatProvider);
        return [
          for (final m in c.messages)
            '${m.fromAgent ? 'Coach' : 'You'}: ${m.text.values.first}',
        ];
    }
  }

  void _view(BuildContext context, WidgetRef ref, AppLanguage language) {
    final lines = _lines(ref, language);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(tr('data.view_title', language), style: AppText.cardTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (lines.isEmpty)
                Text(tr('data.none', language), style: AppText.body)
              else
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.gap8),
                    child: Text(line, style: AppText.body),
                  ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr('data.close', language)),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    AppLanguage language,
  ) async {
    final ok = await _ask(
      context,
      language,
      title: tr('data.confirm_title', language),
      body: tr('data.confirm_body', language),
    );
    if (!ok) return;
    switch (section) {
      case DataSection.about:
        ref.read(settingsProvider.notifier).reset();
      case DataSection.habit:
        ref.read(chatProvider.notifier).clearHabit();
      case DataSection.plan:
        ref.read(dayProvider.notifier).clearPlan();
        ref.read(chatProvider.notifier).clearSteps();
      case DataSection.log:
        ref.read(dayProvider.notifier).clearLog();
      case DataSection.chat:
        ref.read(chatProvider.notifier).clearMessages();
    }
  }
}

/// Asks once. Returns true only when the user confirms.
Future<bool> _ask(
  BuildContext context,
  AppLanguage language, {
  required String title,
  required String body,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(title, style: AppText.cardTitle),
      content: Text(body, style: AppText.body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(tr('data.cancel', language)),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.coral,
            foregroundColor: AppColors.bg,
          ),
          child: Text(tr('data.confirm_yes', language)),
        ),
      ],
    ),
  );
  return result ?? false;
}
