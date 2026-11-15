import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/tabs.dart';
import '../components/bottom_nav.dart';
import '../i18n/language.dart';
import 'chat_page.dart';
import 'today_page.dart';

/// The four tabs with the bottom nav. Plan and History are added in their screen commits.
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final tab = ref.watch(tabProvider);

    return Scaffold(
      body: IndexedStack(
        index: tab.index,
        children: const [
          ChatPage(),
          TodayPage(),
          SizedBox.shrink(),
          SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNav(
          current: tab,
          labels: [
            tr('nav.chat', language),
            tr('nav.today', language),
            tr('nav.plan', language),
            tr('nav.history', language),
          ],
          onSelect: ref.read(tabProvider.notifier).select,
        ),
      ),
    );
  }
}
