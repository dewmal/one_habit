import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/projects.dart';
import '../app/tabs.dart';
import '../components/side_menu.dart';
import 'chat_page.dart';
import 'history_page.dart';
import 'plan_page.dart';
import 'today_page.dart';
import 'topic_chat_page.dart';

/// The app after onboarding: one view of the open habit at a time, and a
/// side menu to move between habits, chats and views.
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(tabProvider);
    final chat = ref.watch(projectsProvider.select((s) => s.currentChat));

    // General stays mounted so its conversation and scroll position are kept.
    return Scaffold(
      drawer: const SideMenu(),
      body: IndexedStack(
        index: tab.index,
        children: [
          chat.general
              ? const ChatPage()
              : TopicChatPage(key: ValueKey(chat.id), chat: chat),
          const TodayPage(),
          const PlanPage(),
          const HistoryPage(),
        ],
      ),
    );
  }
}
