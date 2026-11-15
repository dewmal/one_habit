import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'chat_header.dart' show SunsetAvatar;

/// One system notification: app name and time, a title, a line, and three buttons.
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.appName,
    required this.time,
    required this.title,
    required this.body,
    required this.doneLabel,
    required this.laterLabel,
    required this.tooHardLabel,
    required this.onDone,
    required this.onLater,
    required this.onTooHard,
  });

  final String appName;
  final String time;
  final String title;
  final String body;
  final String doneLabel;
  final String laterLabel;
  final String tooHardLabel;
  final VoidCallback onDone;
  final VoidCallback onLater;
  final VoidCallback onTooHard;

  static const _ink = Color(0xFF1E2444);
  static const _muted = Color(0xFF5A5F80);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.gap16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 24, height: 24, child: SunsetAvatar()),
              const SizedBox(width: AppSpacing.gap8),
              Expanded(
                child: Text(
                  appName,
                  style: AppText.smallLabel.copyWith(color: _muted),
                ),
              ),
              Text(time, style: AppText.smallLabel.copyWith(color: _muted)),
            ],
          ),
          const SizedBox(height: AppSpacing.gap8),
          Text(title, style: AppText.cardTitle.copyWith(color: _ink)),
          const SizedBox(height: 4),
          Text(body, style: AppText.body.copyWith(color: _ink)),
          const SizedBox(height: AppSpacing.gap12),
          Row(
            children: [
              Expanded(
                child: _NotifButton(
                  label: doneLabel,
                  filled: true,
                  onPressed: onDone,
                ),
              ),
              const SizedBox(width: AppSpacing.gap8),
              Expanded(
                child: _NotifButton(
                  label: laterLabel,
                  filled: false,
                  onPressed: onLater,
                ),
              ),
              const SizedBox(width: AppSpacing.gap8),
              Expanded(
                child: _NotifButton(
                  label: tooHardLabel,
                  filled: false,
                  onPressed: onTooHard,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotifButton extends StatelessWidget {
  const _NotifButton({
    required this.label,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = filled ? NotificationCard._ink : AppColors.blush;
    final textColor = filled ? Colors.white : NotificationCard._ink;
    return SizedBox(
      height: AppSpacing.minTouch,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.smallButton),
          ),
          textStyle: AppText.body.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        child: FittedBox(child: Text(label)),
      ),
    );
  }
}
