import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The step-up offer: fixed question on a sunset header, two lines, Yes / Not yet.
class StepUpCard extends StatelessWidget {
  const StepUpCard({
    super.key,
    required this.question,
    required this.nowLine,
    required this.biggerLine,
    required this.yesLabel,
    required this.notYetLabel,
    required this.nothingChanges,
    required this.onYes,
    required this.onNotYet,
  });

  final String question;
  final String nowLine;
  final String biggerLine;
  final String yesLabel;
  final String notYetLabel;
  final String nothingChanges;
  final VoidCallback onYes;
  final VoidCallback onNotYet;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.blush,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: const BoxDecoration(gradient: sunsetGradient),
            padding: const EdgeInsets.all(AppSpacing.gap16),
            child: Text(
              question,
              style: AppText.cardTitle.copyWith(
                color: AppColors.bg,
                fontSize: 20,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.gap16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nowLine,
                  style: AppText.body.copyWith(color: AppColors.bg),
                ),
                const SizedBox(height: 4),
                Text(
                  biggerLine,
                  style: AppText.body.copyWith(color: AppColors.bg),
                ),
                const SizedBox(height: AppSpacing.gap12),
                Row(
                  children: [
                    Expanded(
                      child: _Button(
                        label: yesLabel,
                        color: AppColors.bg,
                        textColor: AppColors.text,
                        onPressed: onYes,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.gap8),
                    Expanded(
                      child: _Button(
                        label: notYetLabel,
                        color: AppColors.blushDeep,
                        textColor: AppColors.bg,
                        onPressed: onNotYet,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.gap12),
                Text(
                  nothingChanges,
                  style: AppText.bodyMuted.copyWith(color: AppColors.bg),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.mainButtonHeight,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.smallButton + 2),
          ),
          textStyle: AppText.cardTitle,
        ),
        child: Text(label),
      ),
    );
  }
}
