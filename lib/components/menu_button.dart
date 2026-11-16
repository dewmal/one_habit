import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/language.dart';
import '../theme/app_theme.dart';

/// 44 px rounded square with three lines. Opens the side menu of the
/// nearest Scaffold. Top left on every screen after onboarding.
class MenuButton extends ConsumerWidget {
  const MenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton.filled(
      onPressed: () => Scaffold.of(context).openDrawer(),
      tooltip: tr('menu.open', ref.watch(languageProvider)),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(AppSpacing.minTouch),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.iconButton),
        ),
      ),
      icon: const Icon(Icons.menu),
    );
  }
}
