import 'package:LinkLian/core/constants/colors.dart';
import 'package:LinkLian/core/constants/linklian-icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class AIChatInputBarWidget extends StatelessWidget {
  final TextEditingController textController;
  final bool hasText;
  final bool isAiResponding;
  final bool canGenerateQuiz;
  final VoidCallback? onGenerateQuiz;
  final VoidCallback? onSendMessage;

  const AIChatInputBarWidget({
    super.key,
    required this.textController,
    required this.hasText,
    required this.isAiResponding,
    required this.canGenerateQuiz,
    this.onGenerateQuiz,
    this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
          child: Row(
            children: [
              InkWell(
                onTap: canGenerateQuiz ? onGenerateQuiz : null,
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPalette[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LinkLianIcon.fileTextSpark,
                    color: AppColors.primaryPalette[500],
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryPalette[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: textController,
                          decoration: const InputDecoration(
                            hintText: 'Aa...',
                            hintStyle: TextStyle(
                              color: Color(0xFFBDBDBD),
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                          ),
                          style: const TextStyle(fontSize: 15),
                          minLines: 1,
                          maxLines: 4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (hasText)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primaryPalette[500],
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: isAiResponding
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : Icon(
                                      TablerIcons.send,
                                      color: AppColors.white,
                                      size: 20,
                                    ),
                              onPressed: isAiResponding ? null : onSendMessage,
                              padding: const EdgeInsets.all(10),
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}