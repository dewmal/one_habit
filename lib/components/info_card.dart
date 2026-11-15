import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Surface box with a yellow outline and icon. Fixed text only.
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.text,
    this.title,
    this.icon = Icons.info_outline,
  });

  final String text;
  final String? title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gap16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.sunsetYellow, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.sunsetYellow),
          const SizedBox(width: AppSpacing.gap12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) Text(title!, style: AppText.cardTitle),
                Text(text, style: AppText.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
