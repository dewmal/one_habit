import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Outlined pill buttons under the last agent message. A tap is sent as the answer.
class QuickReplies extends StatelessWidget {
  const QuickReplies({super.key, required this.labels, required this.onTap});

  final List<String> labels;
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.gap8,
      runSpacing: AppSpacing.gap8,
      children: [
        for (var i = 0; i < labels.length; i++)
          OutlinedButton(
            onPressed: () => onTap(i),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text,
              minimumSize: const Size(0, AppSpacing.minTouch),
              side: const BorderSide(color: AppColors.coralBright, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.quickReply),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              textStyle: AppText.cardTitle,
            ),
            child: Text(labels[i]),
          ),
      ],
    );
  }
}
