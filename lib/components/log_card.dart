import 'package:flutter/material.dart';

import '../app/day_state.dart';
import '../theme/app_theme.dart';
import 'blush_card.dart';
import 'three_choice.dart';

/// The evening check-in: each task Done / Partly / Skipped, then Easy / Okay / Hard.
class LogCard extends StatefulWidget {
  const LogCard({
    super.key,
    required this.tasks,
    required this.initialResults,
    required this.resultLabels,
    required this.feelingLabels,
    required this.feelingHeading,
    required this.saveLabel,
    required this.onSave,
  });

  final List<String> tasks;
  final Map<int, TaskResult> initialResults;

  /// Done, Partly, Skipped, in [TaskResult] order.
  final List<String> resultLabels;

  /// Easy, Okay, Hard, in [Feeling] order.
  final List<String> feelingLabels;
  final String feelingHeading;
  final String saveLabel;
  final void Function(Map<int, TaskResult> results, Feeling feeling) onSave;

  @override
  State<LogCard> createState() => _LogCardState();
}

class _LogCardState extends State<LogCard> {
  late final Map<int, TaskResult> _results = Map.of(widget.initialResults);
  Feeling? _feeling;

  bool get _complete =>
      _feeling != null && _results.length == widget.tasks.length;

  @override
  Widget build(BuildContext context) {
    return BlushCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < widget.tasks.length; i++) ...[
            Text(
              widget.tasks[i],
              style: AppText.body.copyWith(color: AppColors.bg),
            ),
            const SizedBox(height: AppSpacing.gap8),
            ThreeChoice(
              labels: widget.resultLabels,
              selected: _results[i]?.index,
              onChanged: (choice) =>
                  setState(() => _results[i] = TaskResult.values[choice]),
            ),
            const SizedBox(height: AppSpacing.gap12),
          ],
          const Divider(color: AppColors.blushDeep, height: 24),
          Text(
            widget.feelingHeading,
            style: AppText.smallLabel.copyWith(color: AppColors.labelOnBlush),
          ),
          const SizedBox(height: AppSpacing.gap8),
          ThreeChoice(
            labels: widget.feelingLabels,
            selected: _feeling?.index,
            onChanged: (choice) =>
                setState(() => _feeling = Feeling.values[choice]),
          ),
          const SizedBox(height: AppSpacing.gap16),
          SizedBox(
            width: double.infinity,
            height: AppSpacing.mainButtonHeight,
            child: FilledButton(
              onPressed: _complete
                  ? () => widget.onSave(Map.of(_results), _feeling!)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: AppColors.bg,
                disabledBackgroundColor: AppColors.blushDeep,
                disabledForegroundColor: AppColors.labelOnBlush,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.mainButton),
                ),
                textStyle: AppText.cardTitle,
              ),
              child: Text(widget.saveLabel),
            ),
          ),
        ],
      ),
    );
  }
}
