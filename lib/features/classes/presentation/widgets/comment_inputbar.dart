import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/linklian-icon.dart';
import '../../../auth/controller/auth_controller.dart';
import '../controllers/comment_controller.dart';

class CommentInputBar extends StatelessWidget {
  final CommentController controller;
  final bool isUserDeleted;

  const CommentInputBar({
    super.key,
    required this.controller,
    this.isUserDeleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final isTeacher =
        auth.roleName.value == 'teacher' || auth.roleName.value == 'instructor';

    if (isUserDeleted) {
      return Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            ),
            child: const Text(
              'ไม่สามารถแสดงความคิดเห็นบนโพสต์นี้ได้',
              style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ===== REPLYING TO BAR =====
          Obx(() {
            final replyingComment = controller.replyingTo.value;
            if (replyingComment == null) {
              return const SizedBox.shrink();
            }

            // ✅ แสดงชื่อที่ backend ส่งมา (รวม Anonymous xxxx หรือชื่อจริง)
            final displayName = replyingComment.effectiveDisplayName;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryPalette[50],
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.primaryPalette[100]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.reply_rounded,
                    size: 18,
                    color: AppColors.primaryPalette[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ตอบกลับ $displayName',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primaryPalette[700],
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (replyingComment.commentText.isNotEmpty)
                          Text(
                            replyingComment.commentText,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => controller.replyingTo.value = null,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.gray,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // ===== INPUT BAR =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // ===== TOGGLE ANONYMOUS =====
                  if (!isTeacher)
                    Obx(
                      () => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildIconToggleSwitch(
                          value: controller.isAnonymous.value,
                          onChanged: (v) => controller.isAnonymous.value = v,
                        ),
                      ),
                    ),

                  // ===== INPUT =====
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Obx(
                        () => TextField(
                          controller: controller.textController,
                          focusNode: controller.focusNode,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            hintText: controller.replyingTo.value != null
                                ? 'พิมพ์ข้อความตอบกลับ...'
                                : 'แสดงความคิดเห็น...',
                            hintStyle: TextStyle(
                              color: AppColors.gray.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // ===== SEND BUTTON =====
                  GestureDetector(
                    onTap: _submit,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                      child: const Center(
                        child: Icon(
                          LinkLianIcon.send,
                          color: AppColors.black,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final text = controller.textController.text.trim();
    if (text.isEmpty) return;

    controller.submitComment(text);
    controller.textController.clear();
    controller.focusNode.unfocus();
  }

  /// ===== SAME TOGGLE AS CREATE POST =====
  Widget _buildIconToggleSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 72,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: value
              ? AppColors.primaryPalette[300]
              : AppColors.primaryPalette[100],
          border: Border.all(
            color: value
                ? AppColors.primaryPalette[500]!
                : AppColors.primaryPalette[300]!,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  LinkLianHugeIcon.anonymous(
                    size: 18,
                    color: value
                        ? AppColors.primaryPalette[500]!
                        : AppColors.primaryPalette[300]!,
                  ),
                  Icon(
                    LinkLianIcon.identifiedUser,
                    size: 18,
                    color: !value
                        ? AppColors.primaryPalette[500]
                        : AppColors.primaryPalette[100],
                  ),
                ],
              ),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: value ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryPalette[900],
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: value
                    ? LinkLianHugeIcon.anonymous(
                        size: 18,
                        color: AppColors.white,
                      )
                    : Icon(
                        LinkLianIcon.identifiedUser,
                        size: 18,
                        color: AppColors.white,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
