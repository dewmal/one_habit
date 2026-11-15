import 'package:flutter/material.dart';

import '../i18n/language.dart';
import '../theme/app_theme.dart';

/// English / සිංහල segmented control. The selected side is coral.
class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AppLanguage value;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        children: [
          _option('English', AppLanguage.en),
          _option('සිංහල', AppLanguage.si),
        ],
      ),
    );
  }

  Widget _option(String label, AppLanguage language) {
    final selected = value == language;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(language),
        child: Container(
          height: AppSpacing.minTouch,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.coral : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.smallButton),
          ),
          child: Text(
            label,
            style: AppText.cardTitle.copyWith(
              color: selected ? AppColors.bg : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}
