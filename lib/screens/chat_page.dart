import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chat/chat_controller.dart';
import '../components/chat_bubbles.dart';
import '../components/chat_header.dart';
import '../components/input_bar.dart';
import '../components/quick_replies.dart';
import '../i18n/language.dart';
import '../theme/app_theme.dart';

/// The General chat. Onboarding and the main app share this page.
class ChatPage extends ConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final chat = ref.watch(chatProvider);
    final controller = ref.read(chatProvider.notifier);
    final messages = chat.messages;
    final lastAgentIndex = messages.lastIndexWhere((m) => m.fromAgent);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ChatHeader(
              title: tr('chat.general', language),
              subtitle: tr('chat.coach', language),
            ),
            Expanded(
              child: ListView(
                reverse: true,
                padding: const EdgeInsets.all(AppSpacing.gap16),
                children: _newestFirst(
                  messages,
                  lastAgentIndex,
                  language,
                  controller,
                ),
              ),
            ),
            InputBar(
              hint: tr('chat.input_hint', language),
              onSend: controller.send,
            ),
          ],
        ),
      ),
    );
  }

  /// The list is reversed so the newest message sits at the bottom.
  List<Widget> _newestFirst(
    List<ChatMessage> messages,
    int lastAgentIndex,
    AppLanguage language,
    ChatController controller,
  ) {
    final items = <Widget>[];
    for (var i = 0; i < messages.length; i++) {
      items.add(_message(messages[i], language));
      if (i == lastAgentIndex && messages[i].replies.isNotEmpty) {
        items.add(const SizedBox(height: AppSpacing.gap8));
        items.add(
          QuickReplies(
            labels: [
              for (final r in messages[i].replies) resolve(r.label, language),
            ],
            onTap: (index) =>
                controller.send('', reply: messages[i].replies[index]),
          ),
        );
      }
    }
    return items.reversed.toList();
  }

  Widget _message(ChatMessage message, AppLanguage language) {
    final text = resolve(message.text, language);
    if (!message.fromAgent) return UserBubble(text: text);
    return AgentBubble(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.questionLabel != null) ...[
            Text(
              resolve(message.questionLabel!, language),
              style: AppText.smallLabel,
            ),
            const SizedBox(height: 4),
          ],
          Text(text, style: AppText.body),
        ],
      ),
    );
  }
}
