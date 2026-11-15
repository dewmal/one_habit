import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Blush box with radius 20. The base for every interactive card in chat.
class BlushCard extends StatelessWidget {
  const BlushCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.gap16),
      decoration: BoxDecoration(
        color: AppColors.blush,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: child,
    );
  }
}
