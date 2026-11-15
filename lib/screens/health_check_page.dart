import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/progress_segments.dart';
import '../i18n/language.dart';
import '../plugins/fitness_plugin.dart';
import '../theme/app_theme.dart';

/// Screen 3: fixed yes/no questions, plain code, no AI. Answers stay on the phone.
/// Pops with the list of answers (true = Yes) when the last question is done.
class HealthCheckPage extends ConsumerStatefulWidget {
  const HealthCheckPage({super.key});

  @override
  ConsumerState<HealthCheckPage> createState() => _HealthCheckPageState();
}

class _HealthCheckPageState extends ConsumerState<HealthCheckPage> {
  final _answers = <bool>[];

  List<Map<AppLanguage, String>> get _questions =>
      fitnessPlugin.healthCheck?.questions ?? const [];

  void _answer(bool yes) {
    _answers.add(yes);
    if (_answers.length == _questions.length) {
      Navigator.of(context).pop(List<bool>.of(_answers));
    } else {
      setState(() {});
    }
  }

  void _back() {
    if (_answers.isEmpty) return;
    setState(_answers.removeLast);
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final index = _answers.length;
    final total = _questions.length;

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
              Row(
                children: [
                  _BackButton(onPressed: index == 0 ? null : _back),
                  const SizedBox(width: AppSpacing.gap12),
                  Expanded(
                    child: Text(
                      tr('health.title', language),
                      style: AppText.cardTitle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.gap16),
              Text(
                resolve(
                  textOf('health.question_label', {
                    'n': '${index + 1}',
                    'total': '$total',
                  }),
                  language,
                ),
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: AppSpacing.gap8),
              ProgressSegments(total: total, current: index + 1),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _HeartIcon(),
                      const SizedBox(height: 24),
                      Text(
                        resolve(_questions[index], language),
                        style: AppText.healthQuestion,
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _ChoiceButton(
                      label: tr('health.no', language),
                      color: AppColors.text,
                      onPressed: () => _answer(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.gap12),
                  Expanded(
                    child: _ChoiceButton(
                      label: tr('health.yes', language),
                      color: AppColors.blush,
                      onPressed: () => _answer(true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.gap16),
              Text(
                tr('health.reassure', language),
                textAlign: TextAlign.center,
                style: AppText.bodyMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: IconButton.filled(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.text,
        ),
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
      ),
    );
  }
}

class _HeartIcon extends StatelessWidget {
  const _HeartIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: sunsetGradient,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: const Icon(Icons.favorite_border, color: AppColors.bg, size: 36),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.mainButtonHeight,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.mainButton),
          ),
          textStyle: AppText.cardTitle,
        ),
        child: Text(label),
      ),
    );
  }
}
