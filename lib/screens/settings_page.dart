import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/settings_state.dart';
import '../components/language_switch.dart';
import '../components/setting_row.dart';
import '../i18n/language.dart';
import '../theme/app_theme.dart';

/// Screen 13: language, reminders and quiet hours. Each change saves at once.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            Row(
              children: [
                IconButton.filled(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.text,
                  ),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                ),
                const SizedBox(width: AppSpacing.gap12),
                Text(
                  tr('settings.title', language),
                  style: AppText.screenTitleSmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.gap16),
            _Label(tr('settings.language', language)),
            LanguageSwitch(
              value: language,
              onChanged: ref.read(languageProvider.notifier).set,
            ),
            const SizedBox(height: AppSpacing.gap16),
            _Label(tr('settings.reminders', language)),
            SettingRow(
              label: tr('settings.most_reminders', language),
              trailing: _Stepper(
                value: '${settings.dailyLimit}',
                onMinus: () => controller.changeDailyLimit(-1),
                onPlus: () => controller.changeDailyLimit(1),
              ),
            ),
            const SizedBox(height: AppSpacing.gap10),
            SettingRow(
              label: tr('settings.morning', language),
              value: formatTime(settings.morning),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: settings.morning,
                );
                if (picked != null) controller.setMorning(picked);
              },
            ),
            const SizedBox(height: AppSpacing.gap10),
            SettingRow(
              label: tr('settings.evening', language),
              value: formatTime(settings.evening),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: settings.evening,
                );
                if (picked != null) controller.setEvening(picked);
              },
            ),
            const SizedBox(height: AppSpacing.gap10),
            SettingRow(
              label: tr('settings.quiet', language),
              value:
                  '${formatTime(settings.quietStart)} to ${formatTime(settings.quietEnd)}',
              onTap: () async {
                final start = await showTimePicker(
                  context: context,
                  initialTime: settings.quietStart,
                );
                if (start == null || !context.mounted) return;
                final end = await showTimePicker(
                  context: context,
                  initialTime: settings.quietEnd,
                );
                if (end != null) {
                  controller.setQuiet(start: start, end: end);
                }
              },
            ),
            const SizedBox(height: AppSpacing.gap16),
            _Label(tr('settings.privacy', language)),
            SettingRow(label: tr('settings.my_data', language), onTap: () {}),
            const SizedBox(height: 24),
            Text(tr('settings.lost_phone', language), style: AppText.bodyMuted),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gap8),
      child: Text(text, style: AppText.smallLabel),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(icon: Icons.remove, onPressed: onMinus),
        SizedBox(
          width: 40,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: AppText.cardTitle,
          ),
        ),
        _StepButton(icon: Icons.add, onPressed: onPlus),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSpacing.minTouch,
      height: AppSpacing.minTouch,
      child: IconButton.filled(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surfaceRaised,
          foregroundColor: AppColors.text,
        ),
        icon: Icon(icon),
      ),
    );
  }
}
