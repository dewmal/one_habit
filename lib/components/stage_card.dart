import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Current stage on a sunset gradient. Text on it is navy.
class StageCard extends StatelessWidget {
  const StageCard({
    super.key,
    required this.stageLabel,
    required this.name,
    required this.line,
  });

  final String stageLabel;
  final String name;
  final String line;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.screen),
      decoration: BoxDecoration(
        gradient: sunsetGradient,
        borderRadius: BorderRadius.circular(AppRadii.stageCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stageLabel,
            style: AppText.smallLabel.copyWith(color: AppColors.bg),
          ),
          const SizedBox(height: AppSpacing.gap8),
          Text(
            name,
            style: AppText.cardTitle.copyWith(
              color: AppColors.bg,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: AppSpacing.gap8),
          Text(line, style: AppText.body.copyWith(color: AppColors.bg)),
        ],
      ),
    );
  }
}
