import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/projects.dart';
import '../components/main_button.dart';
import '../i18n/language.dart';
import '../theme/app_theme.dart';

/// Opens the New chat screen from a plus button.
void openNewChat(NavigatorState navigator) => navigator.push(
  MaterialPageRoute<void>(builder: (_) => const NewChatPage()),
);

/// Pick a topic or name your own chat. Every chat in a habit shares one
/// memory, and only General can change the plan.
class NewChatPage extends ConsumerStatefulWidget {
  const NewChatPage({super.key});

  @override
  ConsumerState<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends ConsumerState<NewChatPage> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _start(String name) async {
    final started = await ref.read(projectsProvider.notifier).startChat(name);
    if (started && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final habit = ref.watch(projectsProvider).current.name;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton.filled(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      fixedSize: const Size.square(AppSpacing.minTouch),
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.text,
                    ),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  const SizedBox(width: AppSpacing.gap12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('newchat.title', language),
                          style: AppText.screenTitle,
                        ),
                        Text(
                          tr(
                            'newchat.in',
                            language,
                          ).replaceAll('{habit}', habit),
                          style: AppText.bodyMuted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.gap16),
              Text(tr('newchat.pick', language), style: AppText.smallLabel),
              const SizedBox(height: AppSpacing.gap8),
              for (final topic in newChatTopics) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  onTap: () => _start(topic),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.gap16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.card),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: AppColors.sunsetYellow,
                        ),
                        const SizedBox(width: AppSpacing.gap16),
                        Expanded(child: Text(topic, style: AppText.cardTitle)),
                        const Icon(Icons.chevron_right, color: AppColors.text),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.gap10),
              ],
              const SizedBox(height: AppSpacing.gap12),
              Text(tr('newchat.own', language), style: AppText.smallLabel),
              const SizedBox(height: AppSpacing.gap8),
              TextField(
                controller: _name,
                style: AppText.body,
                textInputAction: TextInputAction.done,
                onSubmitted: _start,
                decoration: InputDecoration(
                  hintText: tr('newchat.name_hint', language),
                  hintStyle: AppText.bodyMuted,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.all(AppSpacing.gap16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const Spacer(),
              Text(tr('newchat.note', language), style: AppText.bodyMuted),
              const SizedBox(height: AppSpacing.gap16),
              MainButton(
                label: tr('newchat.start', language),
                onPressed: () => _start(_name.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
