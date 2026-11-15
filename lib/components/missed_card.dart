import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'blush_card.dart';

/// Tomorrow's smaller step, with a "Smaller" tag and the before and after counts.
class MissedCard extends StatelessWidget {
  const MissedCard({
    super.key,
    required this.heading,
    required this.smallerTag,
    required this.step,
    required this.comparison,
  });

  final String heading;
  final String smallerTag;
  final String step;
  final String comparison;

  @override
  Widget build(BuildContext context) {
    return BlushCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  heading,
                  style: AppText.smallLabel.copyWith(
                    color: AppColors.labelOnBlush,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gap12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(AppRadii.smallButton),
                ),
                child: Text(smallerTag, style: AppText.smallLabel),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.gap12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.gap16),
            decoration: BoxDecoration(
              color: AppColors.text,
              borderRadius: BorderRadius.circular(AppRadii.row),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_box_outline_blank, color: AppColors.bg),
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
          const SizedBox(height: AppSpacing.gap12),
          Text(comparison, style: AppText.body.copyWith(color: AppColors.bg)),
        ],
      ),
    );
  }
}
