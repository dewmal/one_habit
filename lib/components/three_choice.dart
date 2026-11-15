import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Three equal buttons in a row. The selected one is navy with white text.
class ThreeChoice extends StatelessWidget {
  const ThreeChoice({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;

  /// Index of the selected choice, or null for none.
  final int? selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: SizedBox(
              height: AppSpacing.minTouch + 4,
              child: FilledButton(
                onPressed: () => onChanged(i),
                style: FilledButton.styleFrom(
                  backgroundColor: i == selected
                      ? AppColors.bg
                      : AppColors.blushDeep,
                  foregroundColor: i == selected
                      ? AppColors.text
                      : AppColors.bg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.smallButton),
                  ),
                  textStyle: AppText.body.copyWith(fontWeight: FontWeight.w600),
                ),
                child: Text(labels[i]),
              ),
            ),
          ),
          if (i < labels.length - 1) const SizedBox(width: AppSpacing.gap8),
        ],
      ],
    );
  }
}
