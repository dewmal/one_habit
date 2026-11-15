import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_state.dart';
import '../components/info_card.dart';
import '../components/language_switch.dart';
import '../components/main_button.dart';
import '../components/sunset_art.dart';
import '../i18n/language.dart';
import '../theme/app_theme.dart';

/// Screen 1: first-run welcome. Shows the AI note without scrolling.
class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenWide,
            vertical: AppSpacing.screen,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(flex: 5, child: SunsetArt()),
              const SizedBox(height: AppSpacing.gap16),
              Text(tr('app.name', language), style: AppText.welcomeTitle),
              const SizedBox(height: AppSpacing.gap8),
              Text(tr('welcome.promise', language), style: AppText.bodyMuted),
              const SizedBox(height: AppSpacing.gap16),
              InfoCard(text: tr('welcome.ai_note', language)),
              const SizedBox(height: AppSpacing.gap16),
              LanguageSwitch(
                value: language,
                onChanged: ref.read(languageProvider.notifier).set,
              ),
              const Spacer(),
              MainButton(
                label: tr('welcome.start', language),
                onPressed: ref.read(appProvider.notifier).startOnboarding,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
