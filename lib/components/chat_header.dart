import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Gradient avatar, chat name and a "Your coach · AI" line.
class ChatHeader extends StatelessWidget {
  const ChatHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgDeep,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.gap12,
        AppSpacing.screen,
        AppSpacing.gap16,
      ),
      child: Row(
        children: [
          const SunsetAvatar(),
          const SizedBox(width: AppSpacing.gap12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.screenTitleSmall),
                Text(subtitle, style: AppText.bodyMuted),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// The coach avatar: a small sunset gradient square.
class SunsetAvatar extends StatelessWidget {
  const SunsetAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: sunsetGradient,
        borderRadius: BorderRadius.circular(AppRadii.iconButton),
      ),
    );
  }
}
