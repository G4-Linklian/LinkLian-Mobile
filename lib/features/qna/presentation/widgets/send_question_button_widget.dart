import 'package:LinkLian/core/constants/colors.dart';
import 'package:LinkLian/core/constants/linklian-icon.dart';
import 'package:flutter/material.dart';

class SendQuestionButtonWidget extends StatelessWidget {
  final TextEditingController textController;
  final bool isLoading;
  final VoidCallback onPressed;

  const SendQuestionButtonWidget({
    super.key,
    required this.textController,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: textController,
      builder: (context, value, _) {
        final canSend = value.text.trim().isNotEmpty;

        return GestureDetector(
          onTap: canSend ? onPressed : null,
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            child: Center(
              child: Icon(
                LinkLianIcon.send,
                color: canSend
                    ? AppColors.primaryPalette[900]
                    : AppColors.primaryPalette[300],
                size: 22,
              ),
            ),
          ),
        );
      },
    );
  }
}
