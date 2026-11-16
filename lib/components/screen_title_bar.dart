import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'menu_button.dart';

/// Menu button at the left, then a big title and a muted line under it.
class ScreenTitleBar extends StatelessWidget {
  const ScreenTitleBar({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const MenuButton(),
        const SizedBox(width: AppSpacing.gap12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.screenTitle),
              Text(subtitle, style: AppText.bodyMuted),
            ],
          ),
        ),
      ],
    );
  }
}
