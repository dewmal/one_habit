import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/day_state.dart';
import '../i18n/language.dart';
import '../theme/app_theme.dart';

/// Screen 12: one row per day, newest first. No scores, no streaks, no warning colours.
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final day = ref.watch(dayProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Today is always the first row: the saved log if there is one, else the live ticks.
    final saved = day.history.where((e) => _sameDay(e.date, today));
    final todayEntry = saved.isNotEmpty
        ? saved.first
        : DayEntry(date: today, results: day.results);
    final rows = [
      todayEntry,
      ...day.history.where((e) => !_sameDay(e.date, today)),
    ];

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          Text(tr('history.title', language), style: AppText.screenTitle),
          const SizedBox(height: 4),
          Text(tr('history.subtitle', language), style: AppText.bodyMuted),
          const SizedBox(height: AppSpacing.gap16),
          for (final entry in rows) ...[
            _DayRow(
              title: _dayName(entry.date, today, language),
              summary: _summary(
                entry,
                tasks: day.tasks.length,
                isToday: _sameDay(entry.date, today),
                language: language,
              ),
              feeling: entry.feeling,
            ),
            const SizedBox(height: AppSpacing.gap10),
          ],
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dayName(DateTime date, DateTime today, AppLanguage language) {
    final yesterday = today.subtract(const Duration(days: 1));
    if (_sameDay(date, today)) return tr('history.today', language);
    if (_sameDay(date, yesterday)) return tr('history.yesterday', language);
    return tr('weekday.${date.weekday}', language);
  }

  String _summary(
    DayEntry entry, {
    required int tasks,
    required bool isToday,
    required AppLanguage language,
  }) {
    if (entry.results.isEmpty) {
      return tr('history.rest', language);
    }
    int count(TaskResult r) => entry.results.values.where((v) => v == r).length;
    final done = count(TaskResult.done);
    final partly = count(TaskResult.partly);
    final skipped = count(TaskResult.skipped);

    if (done == tasks && tasks > 0) {
      return resolve(textOf('history.all_done', {'n': '$tasks'}), language);
    }
    if (skipped == tasks && tasks > 0) {
      return resolve(textOf('history.all_skipped', {'n': '$tasks'}), language);
    }

    final parts = <String>[
      if (done > 0) resolve(textOf('history.done', {'n': '$done'}), language),
      if (partly > 0)
        resolve(textOf('history.partly', {'n': '$partly'}), language),
      if (skipped > 0)
        resolve(textOf('history.skipped', {'n': '$skipped'}), language),
      if (isToday && entry.feeling == null && tasks > entry.results.length)
        resolve(
          textOf('history.not_logged', {
            'n': '${tasks - entry.results.length}',
          }),
          language,
        ),
    ];
    return parts.join(', ');
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.title,
    required this.summary,
    required this.feeling,
  });

  final String title;
  final String summary;
  final Feeling? feeling;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.gap16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.row),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.cardTitle),
                const SizedBox(height: 2),
                Text(summary, style: AppText.bodyMuted),
              ],
            ),
          ),
          if (feeling != null) ...[
            const SizedBox(width: AppSpacing.gap8),
            _FeelingTag(feeling: feeling!),
          ],
        ],
      ),
    );
  }
}

class _FeelingTag extends ConsumerWidget {
  const _FeelingTag({required this.feeling});

  final Feeling feeling;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final key = switch (feeling) {
      Feeling.easy => 'log.easy',
      Feeling.okay => 'log.okay',
      Feeling.hard => 'log.hard',
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gap12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.blush,
        borderRadius: BorderRadius.circular(AppRadii.smallButton),
      ),
      child: Text(
        tr(key, language),
        style: AppText.smallLabel.copyWith(color: AppColors.bg),
      ),
    );
  }
}
