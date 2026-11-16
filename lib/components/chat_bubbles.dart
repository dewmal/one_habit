import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Left side, surface colour. Small bottom-left corner.
class AgentBubble extends StatelessWidget {
  const AgentBubble({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.gap8 / 2),
        padding: const EdgeInsets.all(AppSpacing.gap16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Right side, coral with navy text. Small bottom-right corner.
class UserBubble extends StatelessWidget {
  const UserBubble({
    super.key,
    required this.text,
    this.retryLabel,
    this.onRetry,
  });

  final String text;

  /// Set on a message that could not be answered. The bubble then shows a
  /// "Try again" button under the text.
  final String? retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.gap8 / 2),
        padding: const EdgeInsets.all(AppSpacing.gap16),
        decoration: const BoxDecoration(
          color: AppColors.coral,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: AppText.body.copyWith(color: AppColors.bg)),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.gap8),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.bg,
                  backgroundColor: AppColors.bg.withAlpha(30),
                  minimumSize: const Size(
                    AppSpacing.minTouch,
                    AppSpacing.minTouch,
                  ),
                ),
                child: Text(retryLabel ?? ''),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
