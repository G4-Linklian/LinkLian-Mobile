import 'package:LinkLian/features/community/widgets/community_card_comment.dart';
import 'package:LinkLian/features/community/widgets/community_comment_inputbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/linklian-icon.dart';
import '../../../core/constants/sizes.dart';

import '../controllers/community_comment_controller.dart';
import '../../classes/widgets/comment_inputbar.dart';
import '../../classes/widgets/card_comment.dart';

import '../../../data/model/community_comment_model.dart';

class CommunityCommentPage extends StatelessWidget {
  const CommunityCommentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CommunityCommentController>();
    final scrollController = ScrollController();

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        controller.loadComments(loadMore: true);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'โพสต์',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.black,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LinkLianIcon.back),
          color: AppColors.black,
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshComments,
              child: Obx(
                () => _buildScrollableContent(controller, scrollController),
              ),
            ),
          ),

          CommunityCommentInputBar(controller: controller),
        ],
      ),
    );
  }

  Widget _buildScrollableContent(
    CommunityCommentController controller,
    ScrollController scrollController,
  ) {
    if (controller.isLoading.value && controller.flatComments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final flat = controller.flatComments;

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: flat.isEmpty ? 3 : flat.length + 3,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm,
            ),
            child: controller.postCardWidget,
          );
        }

        if (index == 1) {
          return Container(height: 8, color: const Color(0xFFF5F5F5));
        }

        if (flat.isEmpty) {
          return _buildEmptyState();
        }

        if (index == flat.length + 2) {
          return Obx(() {
            if (!controller.isLoadingMore.value) {
              return const SizedBox.shrink();
            }
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          });
        }

        final commentIndex = index - 2;
        final comment = flat[commentIndex];
        final depth = controller.calculateDepth(comment);
        final hasNextSibling = controller.hasNextSibling(
          flat,
          commentIndex,
          depth,
        );

        final visible = controller.visibleChildrenCount[comment.commentId] ?? 0;

        final remaining = comment.childrenCount - visible;

        return Padding(
          padding: EdgeInsets.only(top: commentIndex == 0 ? 16 : 0),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _ThreadLinePainter(
                    depth: depth,
                    hasNextSibling: hasNextSibling,
                  ),
                ),
              ),

              CardCommentCommunity(
                comment: comment,
                depth: depth,
                currentUserId: controller.userSysId,

                onReply: () {
                  controller.replyingTo.value = comment;
                  controller.focusNode.requestFocus();
                },

                onShowMore: remaining > 0
                    ? () => controller.toggleReplies(comment)
                    : null,

                remainingReplies: remaining,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีความคิดเห็น',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadLinePainter extends CustomPainter {
  final int depth;
  final bool hasNextSibling;

  _ThreadLinePainter({required this.depth, required this.hasNextSibling});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    for (int i = 0; i < depth; i++) {
      final double x = 16.0 + i * 32.0 + 10.0;

      if (hasNextSibling || i < depth - 1) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }

      if (i == depth - 1) {
        canvas.drawLine(Offset(x, 24.0), Offset(x + 16.0, 24.0), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
