import 'package:flutter/material.dart';

import '../app/tabs.dart';
import '../theme/app_theme.dart';

/// Four tabs: Chat, Today, Plan, History. Active tab is coral.
class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.current,
    required this.labels,
    required this.onSelect,
  });

  final AppTab current;

  /// Label for each tab, in [AppTab] order.
  final List<String> labels;
  final ValueChanged<AppTab> onSelect;

  static const _icons = [
    Icons.chat_bubble_outline,
    Icons.check_circle_outline,
    Icons.stairs_outlined,
    Icons.calendar_today_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgDeep,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.gap8),
      child: Row(
        children: [
          for (final tab in AppTab.values) Expanded(child: _item(tab)),
        ],
      ),
    );
  }

  Widget _item(AppTab tab) {
    final active = tab == current;
    final color = active ? AppColors.coralBright : AppColors.textMuted;
    return InkWell(
      onTap: () => onSelect(tab),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icons[tab.index], color: color),
          const SizedBox(height: 2),
          Text(
            labels[tab.index],
            style: AppText.navLabel.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
