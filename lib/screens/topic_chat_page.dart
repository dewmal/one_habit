import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/projects.dart';
import '../components/chat_bubbles.dart';
import '../components/chat_header.dart';
import '../components/info_card.dart';
import '../components/input_bar.dart';
import '../components/quick_replies.dart';
import '../i18n/language.dart';
import '../theme/app_theme.dart';
import 'new_chat_page.dart';

/// A second chat inside the habit. It shares the habit's memory but can only
/// suggest: a plan change goes to General, where the rules decide.
class TopicChatPage extends ConsumerWidget {
  const TopicChatPage({super.key, required this.chat});

  final ChatInfo chat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final habit = ref.watch(projectsProvider).current.name;
    final messages = ref.watch(topicChatsProvider)[chat.id] ?? const [];
    final controller = ref.read(topicChatsProvider.notifier);
    final lastIsSuggestion = messages.isNotEmpty && messages.last.suggestion;

    final items = <Widget>[
      if (messages.isEmpty)
        AgentBubble(
          child: Text(tr('topic.empty', language), style: AppText.body),
        ),
      for (final m in messages)
        if (m.suggestion)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: InfoCard(
              title: tr('topic.suggestion_title', language),
              text: tr('topic.suggestion_body', language),
              icon: Icons.info_outline,
            ),
          )
        else if (m.fromUser)
          UserBubble(text: m.text)
        else
          AgentBubble(child: Text(m.text, style: AppText.body)),
      if (lastIsSuggestion) ...[
        const SizedBox(height: AppSpacing.gap8),
        QuickReplies(
          labels: [
            tr('topic.open_general', language),
            tr('topic.ask_else', language),
          ],
          onTap: (i) {
            if (i == 0) controller.openGeneral();
          },
        ),
      ],
    ];

    return SafeArea(
      child: Column(
        children: [
          ChatHeader(
            title: chat.title,
            subtitle: '$habit · AI',
            avatar: const TopicAvatar(),
            onNewChat: () => openNewChat(Navigator.of(context)),
            newChatTooltip: tr('newchat.title', language),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.gap16),
              children: items,
            ),
          ),
          InputBar(
            hint: tr('chat.input_hint', language),
            onSend: (text) => controller.send(chat.id, chat.title, text),
          ),
        ],
      ),
    );
  }
}
