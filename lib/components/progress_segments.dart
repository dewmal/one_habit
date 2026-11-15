import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// One bar per question. Bars up to [current] are coral, the rest are empty.
class ProgressSegments extends StatelessWidget {
  const ProgressSegments({
    super.key,
    required this.total,
    required this.current,
  });

  final int total;

  /// How many bars are filled (1-based count).
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: i < current ? AppColors.coral : AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          if (i < total - 1) const SizedBox(width: AppSpacing.gap8),
        ],
      ],
    );
  }
}
