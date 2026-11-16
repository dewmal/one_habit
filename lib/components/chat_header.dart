import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'menu_button.dart';
import 'new_chat_button.dart';

/// Menu button, avatar, chat name with the habit name under it, and a
/// plus button for a new chat. Onboarding passes [showMenu] false.
class ChatHeader extends StatelessWidget {
  const ChatHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showMenu = true,
    this.avatar = const SunsetAvatar(),
    this.onNewChat,
    this.newChatTooltip,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final bool showMenu;
  final Widget avatar;
  final VoidCallback? onNewChat;
  final String? newChatTooltip;

  /// Extra controls before the plus button (connection light, debug menu).
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
          if (showMenu) ...[
            const MenuButton(),
            const SizedBox(width: AppSpacing.gap12),
          ],
          avatar,
          const SizedBox(width: AppSpacing.gap12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.screenTitleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: AppText.bodyMuted,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ?trailing,
          if (onNewChat != null)
            NewChatButton(onPressed: onNewChat!, tooltip: newChatTooltip),
        ],
      ),
    );
  }
}

/// The coach avatar: a small sunset gradient square.
class SunsetAvatar extends StatelessWidget {
  const SunsetAvatar({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: sunsetGradient,
        borderRadius: BorderRadius.circular(AppRadii.iconButton),
      ),
    );
  }
}

/// Plain chat icon for topic chats, so they differ from General.
class TopicAvatar extends StatelessWidget {
  const TopicAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadii.iconButton),
      ),
      child: const Icon(
        Icons.chat_bubble_outline,
        color: AppColors.sunsetYellow,
      ),
    );
  }
}
