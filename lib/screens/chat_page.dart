import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/connection_status.dart';
import '../app/app_state.dart';
import '../app/projects.dart';
import '../chat/chat_controller.dart';
import '../components/info_card.dart';
import '../components/log_card.dart';
import '../components/missed_card.dart';
import '../components/step_up_card.dart';
import '../components/level_card.dart';
import '../plugins/fitness_plugin.dart';
import '../components/chat_bubbles.dart';
import '../components/chat_header.dart';
import '../components/input_bar.dart';
import '../components/quick_replies.dart';
import '../i18n/language.dart';
import 'health_check_page.dart';
import 'new_chat_page.dart';
import 'notifications_page.dart';
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

    // Open the health check once the placement questions are done.
    ref.listen(chatProvider.select((s) => s.step), (previous, next) async {
      if (next != OnboardingStep.healthCheck) return;
      final answers = await Navigator.of(context).push<List<bool>>(
        MaterialPageRoute(builder: (_) => const HealthCheckPage()),
      );
      if (answers != null) controller.finishHealthCheck(answers);
    });
    final lastAgentIndex = messages.lastIndexWhere((m) => m.fromAgent);

    // Onboarding is the chat alone: no menu button and no new chat button.
    final inApp =
        ref.watch(appProvider.select((s) => s.phase)) == AppPhase.main;
    final habit = ref.watch(projectsProvider.select((s) => s.current.name));

    // The parent Scaffold (onboarding or MainShell) owns the background and
    // the side menu.
    return SafeArea(
      child: Column(
        children: [
          ChatHeader(
            title: tr('chat.general', language),
            subtitle: inApp ? '$habit · AI' : tr('chat.coach', language),
            showMenu: inApp,
            onNewChat: inApp ? () => openNewChat(Navigator.of(context)) : null,
            newChatTooltip: tr('newchat.title', language),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ConnectionDot(language: language),
                if (kDebugMode) _DemoMenu(controller: controller),
              ],
            ),
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
      items.add(_message(messages[i], language, controller));
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

  Widget _message(
    ChatMessage message,
    AppLanguage language,
    ChatController controller,
  ) {
    final text = resolve(message.text, language);
    if (!message.fromAgent) return UserBubble(text: text);
    final card = message.card;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AgentBubble(
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
        ),
        if (card is HardStopCardData) ...[
          const SizedBox(height: AppSpacing.gap8),
          InfoCard(
            title: tr('hardstop.title', language),
            text: tr('hardstop.body', language),
            icon: Icons.pause_circle_outline,
          ),
        ],
        if (card is StepUpCardData) ...[
          const SizedBox(height: AppSpacing.gap8),
          StepUpCard(
            question: tr('stepup.question', language),
            nowLine: resolve(
              textOf('stepup.now', {'step': card.now}),
              language,
            ),
            biggerLine: resolve(
              textOf('stepup.bigger', {'step': card.bigger}),
              language,
            ),
            yesLabel: tr('stepup.yes', language),
            notYetLabel: tr('stepup.not_yet', language),
            nothingChanges: tr('stepup.nothing_changes', language),
            onYes: () => controller.answerStepUp(message.id, yes: true),
            onNotYet: () => controller.answerStepUp(message.id, yes: false),
          ),
        ],
        if (card is MissedDayCardData) ...[
          const SizedBox(height: AppSpacing.gap8),
          MissedCard(
            heading: tr('missed.card_heading', language),
            smallerTag: tr('missed.smaller', language),
            step: card.step,
            comparison: resolve(
              textOf('missed.comparison', {
                'was': '${card.was}',
                'now': '${card.now}',
              }),
              language,
            ),
          ),
        ],
        if (card is LogCardData) ...[
          const SizedBox(height: AppSpacing.gap8),
          LogCard(
            tasks: card.tasks,
            initialResults: card.initialResults,
            resultLabels: [
              tr('log.done', language),
              tr('log.partly', language),
              tr('log.skipped', language),
            ],
            feelingLabels: [
              tr('log.easy', language),
              tr('log.okay', language),
              tr('log.hard', language),
            ],
            feelingHeading: tr('log.feel', language),
            saveLabel: tr('log.save', language),
            onSave: (results, feeling) =>
                controller.saveDailyLog(message.id, results, feeling),
          ),
        ],
        if (card is LevelCardData) ...[
          const SizedBox(height: AppSpacing.gap8),
          LevelCard(
            levelLabels: {
              for (final level in fitnessPlugin.levels)
                level.id: resolve(level.label, language),
            },
            selected: card.level,
            levelHeading: tr('level.heading', language),
            stepsHeading: tr('level.steps_heading', language),
            steps: card.steps,
          ),
          if (card.healthLock) ...[
            const SizedBox(height: AppSpacing.gap8),
            InfoCard(text: tr('level.gentle_note', language)),
          ],
        ],
      ],
    );
  }
}

/// Debug builds only: starts the scenarios that real rules will trigger later.
class _DemoMenu extends StatelessWidget {
  const _DemoMenu({required this.controller});

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Demo scenarios (debug only)',
      icon: const Icon(Icons.science_outlined, color: AppColors.textMuted),
      onSelected: (value) {
        if (value == 'missed') controller.openMissedDays();
        if (value == 'stepup') controller.openStepUp();
        if (value == 'notifications') {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'missed', child: Text('Demo: missed days')),
        PopupMenuItem(value: 'stepup', child: Text('Demo: step-up offer')),
        PopupMenuItem(
          value: 'notifications',
          child: Text('Demo: notifications'),
        ),
      ],
    );
  }
}

/// A small round light in the title bar: green online, yellow checking,
/// red offline or not set. Tap it to read the status and retry.
class _ConnectionDot extends ConsumerWidget {
  const _ConnectionDot({required this.language});

  final AppLanguage language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectionProvider);
    final (key, color) = switch (status) {
      GatewayState.online => ('conn.online', const Color(0xFF3FA66B)),
      GatewayState.checking => ('conn.checking', const Color(0xFFE0B341)),
      GatewayState.offline => ('conn.offline', const Color(0xFFD0594E)),
      GatewayState.notConfigured => (
        'conn.not_configured',
        const Color(0xFFD0594E),
      ),
    };
    return IconButton(
      tooltip: tr(key, language),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => _ConnectionDialog(language: language),
      ),
      icon: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withAlpha(110), blurRadius: 6)],
        ),
      ),
    );
  }
}

class _ConnectionDialog extends ConsumerWidget {
  const _ConnectionDialog({required this.language});

  final AppLanguage language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectionProvider);
    final key = switch (status) {
      GatewayState.online => 'conn.online',
      GatewayState.checking => 'conn.checking',
      GatewayState.offline => 'conn.offline',
      GatewayState.notConfigured => 'conn.not_configured',
    };
    return AlertDialog(
      title: Text(tr('conn.title', language)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr(key, language)),
          if (gatewayUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(gatewayUrl, style: AppText.bodyMuted),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: ref.read(connectionProvider.notifier).check,
          child: Text(tr('conn.retry', language)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('conn.close', language)),
        ),
      ],
    );
  }
}
