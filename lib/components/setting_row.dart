import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Surface row: label on the left, value or arrow on the right.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
  });

  final String label;
  final String? value;

  /// Replaces [value] when a row needs its own control, such as a stepper.
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.row),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.row),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gap16,
            vertical: AppSpacing.gap12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppText.cardTitle.copyWith(fontSize: 16),
                ),
              ),
              if (trailing != null)
                trailing!
              else if (value != null)
                Text(value!, style: AppText.bodyMuted),
              if (onTap != null && trailing == null)
                const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.gap8),
                  child: Icon(Icons.chevron_right, color: AppColors.text),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
