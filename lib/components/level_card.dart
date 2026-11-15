import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'blush_card.dart';

/// Starting level (one highlighted) and tomorrow's small steps.
class LevelCard extends StatelessWidget {
  const LevelCard({
    super.key,
    required this.levelLabels,
    required this.selected,
    required this.levelHeading,
    required this.stepsHeading,
    required this.steps,
  });

  /// Level id to label, in display order.
  final Map<String, String> levelLabels;
  final String selected;
  final String levelHeading;
  final String stepsHeading;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return BlushCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            levelHeading,
            style: AppText.smallLabel.copyWith(color: AppColors.labelOnBlush),
          ),
          const SizedBox(height: AppSpacing.gap8),
          Row(
            children: [
              for (final entry in levelLabels.entries) ...[
                Expanded(
                  child: _LevelChip(
                    label: entry.value,
                    highlighted: entry.key == selected,
                  ),
                ),
                if (entry.key != levelLabels.keys.last)
                  const SizedBox(width: AppSpacing.gap8),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.gap16),
          Text(
            stepsHeading,
            style: AppText.smallLabel.copyWith(color: AppColors.labelOnBlush),
          ),
          const SizedBox(height: AppSpacing.gap8),
          for (final step in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.gap8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.coral,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.gap12),
                  Expanded(
                    child: Text(
                      step,
                      style: AppText.body.copyWith(color: AppColors.bg),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.label, required this.highlighted});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.minTouch + 4,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: highlighted ? AppColors.bg : AppColors.blushDeep,
        borderRadius: BorderRadius.circular(AppRadii.smallButton),
      ),
      child: Text(
        label,
        style: AppText.cardTitle.copyWith(
          color: highlighted ? AppColors.text : AppColors.labelOnBlush,
        ),
      ),
    );
  }
}
