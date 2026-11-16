import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The views of the open habit, opened from the side menu: a chat, Today,
/// Plan or History. Later app starts open on Today.
enum AppTab { chat, today, plan, history }

class TabController extends Notifier<AppTab> {
  @override
  AppTab build() => AppTab.today;

  void select(AppTab tab) => state = tab;
}

final tabProvider = NotifierProvider<TabController, AppTab>(TabController.new);
