import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// White, 56 px high, navy text. One per screen at most.
class MainButton extends StatelessWidget {
  const MainButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.mainButtonHeight,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.text,
          foregroundColor: AppColors.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.mainButton),
          ),
          textStyle: AppText.cardTitle,
        ),
        child: Text(label),
      ),
    );
  }
}
