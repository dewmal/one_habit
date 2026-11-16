import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/projects.dart';
import '../app/tabs.dart';
import '../i18n/language.dart';
import '../screens/my_data_page.dart';
import '../screens/new_chat_page.dart';
import '../screens/settings_page.dart';
import '../theme/app_theme.dart';
import 'chat_header.dart';
import 'new_chat_button.dart';

/// The left side menu: habits, the open habit's chats and views, and
/// Settings and My data in a bar at the bottom.
class SideMenu extends ConsumerStatefulWidget {
  const SideMenu({super.key});

  @override
  ConsumerState<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends ConsumerState<SideMenu> {
  static const _firstCount = 3;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final projects = ref.watch(projectsProvider);
    final tab = ref.watch(tabProvider);
    final all = projects.projects;
    final visible = _showAll ? all : all.take(_firstCount).toList();
    final hidden = all.length - _firstCount;

    return Drawer(
      width: 304,
      backgroundColor: AppColors.bgDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Row(
                children: [
                  const SunsetAvatar(size: 48),
                  const SizedBox(width: AppSpacing.gap12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('app.name', language),
                          style: AppText.screenTitleSmall,
                        ),
                        Text(
                          projects.current.name,
                          style: AppText.bodyMuted,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: tr('menu.close', language),
                    style: IconButton.styleFrom(
                      fixedSize: const Size.square(AppSpacing.minTouch),
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.text,
                    ),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                tr('menu.habits', language),
                style: AppText.smallLabel,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final project in visible)
                    project.id == projects.currentId
                        ? _OpenHabit(
                            project: project,
                            currentChatId: projects.currentChatId,
                            tab: tab,
                            language: language,
                          )
                        : _HabitRow(project: project),
                  if (hidden > 0)
                    TextButton(
                      onPressed: () => setState(() => _showAll = !_showAll),
                      style: TextButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        minimumSize: const Size(0, AppSpacing.minTouch),
                        foregroundColor: AppColors.textMuted,
                      ),
                      child: Text(
                        _showAll
                            ? tr('menu.fewer', language)
                            : tr(
                                'menu.more',
                                language,
                              ).replaceAll('{n}', '$hidden'),
                        style: AppText.body,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                tr('menu.ai_note', language),
                style: AppText.bodyMuted,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Divider(height: 1, color: AppColors.surface),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  _BarIcon(
                    icon: Icons.tune,
                    tooltip: tr('menu.settings', language),
                    page: const SettingsPage(),
                  ),
                  const SizedBox(width: AppSpacing.gap10),
                  _BarIcon(
                    icon: Icons.lock_outline,
                    tooltip: tr('menu.my_data', language),
                    page: const MyDataPage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A habit that is not open. Tapping it opens it and makes it current.
class _HabitRow extends ConsumerWidget {
  const _HabitRow({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.row),
      onTap: () =>
          ref.read(projectsProvider.notifier).selectProject(project.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        child: Row(
          children: [
            Expanded(child: Text(project.name, style: AppText.cardTitle)),
            const Icon(Icons.chevron_right, color: AppColors.text),
          ],
        ),
      ),
    );
  }
}

/// The open habit: its chats (General pinned first) and its three views.
class _OpenHabit extends ConsumerWidget {
  const _OpenHabit({
    required this.project,
    required this.currentChatId,
    required this.tab,
    required this.language,
  });

  final Project project;
  final String currentChatId;
  final AppTab tab;
  final AppLanguage language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(projectsProvider.notifier);
    final general = project.generalChat;
    final others = project.chats.where((c) => !c.general);
    final inChat = tab == AppTab.chat;

    final navigator = Navigator.of(context);
    void closeThen(VoidCallback action) {
      navigator.pop();
      action();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.gap8),
      padding: const EdgeInsets.all(AppSpacing.gap12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadii.stageCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Row(
              children: [
                Expanded(child: Text(project.name, style: AppText.cardTitle)),
                const Icon(Icons.expand_more, color: AppColors.text),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: inChat && currentChatId == general.id
                  ? AppColors.surface
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.row),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadii.row),
                    onTap: () =>
                        closeThen(() => controller.selectChat(general.id)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const SunsetAvatar(size: 28),
                          const SizedBox(width: AppSpacing.gap12),
                          Text(
                            tr('chat.general', language),
                            style: AppText.cardTitle,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                NewChatButton(
                  tooltip: tr('newchat.title', language),
                  onPressed: () => closeThen(() => openNewChat(navigator)),
                ),
              ],
            ),
          ),
          for (final chat in others)
            InkWell(
              borderRadius: BorderRadius.circular(AppRadii.row),
              onTap: () => closeThen(() => controller.selectChat(chat.id)),
              child: Container(
                decoration: BoxDecoration(
                  color: inChat && currentChatId == chat.id
                      ? AppColors.surface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.row),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.gap12),
                    Expanded(child: Text(chat.title, style: AppText.body)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.gap8),
          Row(
            children: [
              for (final (view, key) in [
                (AppTab.today, 'nav.today'),
                (AppTab.plan, 'nav.plan'),
                (AppTab.history, 'nav.history'),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: FilledButton(
                      onPressed: () => closeThen(
                        () => ref.read(tabProvider.notifier).select(view),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, AppSpacing.minTouch),
                        padding: EdgeInsets.zero,
                        backgroundColor: tab == view
                            ? AppColors.coral
                            : AppColors.surface,
                        foregroundColor: tab == view
                            ? AppColors.bg
                            : AppColors.text,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.row),
                        ),
                      ),
                      child: Text(tr(key, language)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarIcon extends StatelessWidget {
  const _BarIcon({
    required this.icon,
    required this.tooltip,
    required this.page,
  });

  final IconData icon;
  final String tooltip;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: () {
        final navigator = Navigator.of(context);
        navigator.pop();
        navigator.push(MaterialPageRoute(builder: (_) => page));
      },
      style: IconButton.styleFrom(
        fixedSize: const Size(44, 44),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.iconButton),
        ),
      ),
      icon: Icon(icon),
    );
  }
}
