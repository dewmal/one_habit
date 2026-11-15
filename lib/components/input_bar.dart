import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Rounded text field and a white round send button.
class InputBar extends StatefulWidget {
  const InputBar({super.key, required this.hint, required this.onSend});

  final String hint;
  final void Function(String text) onSend;

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgDeep,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gap16,
        AppSpacing.gap8,
        AppSpacing.gap16,
        AppSpacing.gap12,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _submit(),
              style: AppText.body,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppText.bodyMuted,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gap16,
                  vertical: AppSpacing.gap12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.gap8),
          SizedBox(
            width: AppSpacing.minTouch + 4,
            height: AppSpacing.minTouch + 4,
            child: IconButton.filled(
              onPressed: _submit,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.text,
                foregroundColor: AppColors.bg,
              ),
              icon: const Icon(Icons.arrow_forward),
              tooltip: 'Send',
            ),
          ),
        ],
      ),
    );
  }
}
