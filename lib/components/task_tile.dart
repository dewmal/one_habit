import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A row with a checkbox and the task text. A tick writes to today's log, no AI.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.text,
    required this.done,
    required this.onToggle,
  });

  final String text;
  final bool done;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.row),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.row),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gap16),
          child: Row(
            children: [
              Checkbox(
                value: done,
                onChanged: (_) => onToggle(),
                activeColor: AppColors.coral,
                checkColor: AppColors.bg,
                side: const BorderSide(color: AppColors.text, width: 2),
              ),
              const SizedBox(width: AppSpacing.gap8),
              Expanded(
                child: Text(
                  text,
                  style: AppText.body.copyWith(
                    decoration: done ? TextDecoration.lineThrough : null,
                    color: done ? AppColors.textMuted : AppColors.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
