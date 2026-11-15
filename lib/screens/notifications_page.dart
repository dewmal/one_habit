import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/day_state.dart';
import '../app/settings_state.dart';
import '../components/notification_card.dart';
import '../components/sunset_art.dart';
import '../i18n/language.dart';
import '../theme/app_theme.dart';

/// Screen 9 preview: the two daily notifications with their three buttons.
/// The buttons write to today's log without opening the app. Scheduling on
/// the phone is a separate task.
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final _handled = <String>{};

  void _tap(String id, VoidCallback action) {
    action();
    setState(() => _handled.add(id));
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final settings = ref.watch(settingsProvider);
    final day = ref.watch(dayProvider);
    final log = ref.read(dayProvider.notifier);
    // The notifications point at the first task of today.
    const taskIndex = 0;
    final task = day.tasks.isEmpty ? '' : day.tasks[taskIndex];

    final cards = <(String, Widget)>[
      (
        'morning',
        NotificationCard(
          appName: tr('notif.app', language),
          time: formatTime(settings.morning),
          title: tr('notif.morning_title', language),
          body: task.isEmpty
              ? resolve(textOf('notif.nothing_today'), language)
              : resolve(textOf('notif.morning_body', {'task': task}), language),
          doneLabel: tr('log.done', language),
          laterLabel: tr('notif.later', language),
          tooHardLabel: tr('notif.too_hard', language),
          onDone: () =>
              _tap('morning', () => log.setResult(taskIndex, TaskResult.done)),
          onLater: () => _tap('morning', () {}),
          onTooHard: () => _tap(
            'morning',
            () => log.setResult(taskIndex, TaskResult.skipped),
          ),
        ),
      ),
      (
        'evening',
        NotificationCard(
          appName: tr('notif.app', language),
          time: formatTime(settings.evening),
          title: tr('log.question', language),
          body: tr('notif.evening_body', language),
          doneLabel: tr('log.done', language),
          laterLabel: tr('notif.later', language),
          tooHardLabel: tr('notif.too_hard', language),
          onDone: () =>
              _tap('evening', () => log.setResult(taskIndex, TaskResult.done)),
          onLater: () => _tap('evening', () {}),
          onTooHard: () => _tap(
            'evening',
            () => log.setResult(taskIndex, TaskResult.skipped),
          ),
        ),
      ),
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.sunsetPurple,
              AppColors.sunsetPink,
              AppColors.sunsetOrange,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: Row(
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
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen,
                  ),
                  children: [
                    for (final (id, card) in cards)
                      if (!_handled.contains(id)) ...[
                        card,
                        const SizedBox(height: AppSpacing.gap16),
                      ],
                    const SizedBox(height: 200, child: SunsetArt()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
