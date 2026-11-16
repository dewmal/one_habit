import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// White plus button. In chat headers and on the General row of the menu.
class NewChatButton extends StatelessWidget {
  const NewChatButton({super.key, required this.onPressed, this.tooltip});

  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(AppSpacing.minTouch),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.iconButton),
        ),
      ),
      icon: const Icon(Icons.add),
    );
  }
}
