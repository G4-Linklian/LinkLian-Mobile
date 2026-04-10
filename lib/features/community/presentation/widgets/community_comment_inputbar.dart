import 'package:LinkLian/features/community/presentation/controllers/community_detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/linklian-icon.dart';
import '../controllers/community_comment_controller.dart';

class CommunityCommentInputBar extends StatelessWidget {
  final CommunityCommentController controller;

  const CommunityCommentInputBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CommunityDetailController>()) {
      return const SizedBox.shrink();
    }

    final detailController = Get.find<CommunityDetailController>();

    return Obx(() {
      final post = controller.post.value;

      final displayName = "${post?.firstName ?? ''} ${post?.lastName ?? ''}"
          .trim();

      final isPostOwnerDeleted =
          displayName.isEmpty ||
          displayName == "ไม่มีบัญชีผู้ใช้งาน" ||
          displayName.toLowerCase().contains("deleted");

      if (!detailController.canInteract() || isPostOwnerDeleted) {
        //return const SizedBox.shrink();
        return _buildDisabledBar();
      }

      return _buildInputBar(context, detailController);
    });
  }

  Widget _buildInputBar(
    BuildContext context,
    CommunityDetailController detailController,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() {
            final replying = controller.replyingTo.value;

            if (replying == null) {
              return const SizedBox.shrink();
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.primaryPalette[50],
              child: Row(
                children: [
                  Icon(
                    Icons.reply,
                    size: 18,
                    color: AppColors.primaryPalette[600],
                  ),
                  const SizedBox(width: 8),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ตอบกลับ ${replying.displayName ?? "Anonymous"}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryPalette[700],
                          ),
                        ),
                        Text(
                          replying.commentText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      controller.replyingTo.value = null;
                    },
                    child: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            );
          }),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.textController,
                      focusNode: controller.focusNode,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: controller.replyingTo.value != null
                            ? 'พิมพ์ข้อความตอบกลับ...'
                            : 'แสดงความคิดเห็น...',
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    // onTap: () {
                    //   final text = controller.textController.text.trim();
                    //   if (text.isEmpty) return;
                    //   controller.submitComment(text);
                    // },
                    onTap: () {
                      final text = controller.textController.text.trim();

                      final post = controller.post.value;

                      final displayName =
                          "${post?.firstName ?? ''} ${post?.lastName ?? ''}"
                              .trim();

                      final isPostOwnerDeleted =
                          displayName.isEmpty ||
                          displayName == "ไม่มีบัญชีผู้ใช้งาน" ||
                          displayName.toLowerCase().contains("deleted");

                      if (text.isEmpty || isPostOwnerDeleted) return;

                      controller.submitComment(text);
                    },
                    child: const Icon(
                      LinkLianIcon.send,
                      color: AppColors.black,
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

  Widget _buildDisabledBar() {
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
}
