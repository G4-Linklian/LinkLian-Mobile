import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/sizes.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/linklian-icon.dart';

import '../controllers/comment_controller.dart';
import '../widgets/card_post.dart';
import '../widgets/card_comment.dart';
import '../../classes/widgets/comment_inputbar.dart';
import '../../../data/model/comment_model.dart';

class CommentPage extends StatelessWidget {
  const CommentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CommentController>();
    final scrollController = ScrollController();

    // Setup infinite scroll
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        controller.loadComments(loadMore: true);
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'โพสต์',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.black,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LinkLianIcon.back, color: AppColors.black, size: 24),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // ===== SCROLLABLE POST + COMMENTS =====
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => controller.refreshComments(),
              child: Obx(
                () => _buildScrollableContent(controller, scrollController),
              ),
            ),
          ),

          // ===== INPUT =====
          CommentInputBar(controller: controller),
        ],
      ),
    );
  }

  Widget _buildScrollableContent(
    CommentController controller,
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
          if (controller.post == null) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm,
            ),
            child: CardPost(post: controller.post!, onSelectForAI: null),
          );
        }

        // Second item: Divider
        if (index == 1) {
          return Container(height: 8, color: const Color(0xFFF5F5F5));
        }

        // Empty state
        if (flat.isEmpty) {
          return _buildEmptyState();
        }

        // Loading indicator at bottom
        if (index == flat.length + 2) {
          return Obx(() {
            if (!controller.isLoadingMore.value) {
              return const SizedBox.shrink();
            }
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          });
        }

        // Comments (index - 2 because of post and divider)
        final commentIndex = index - 2;
        final comment = flat[commentIndex];
        final depth = _calculateDepth(comment, flat);
        final hasNextSibling = _hasNextSibling(flat, commentIndex, depth);
        final visible = controller.visibleChildrenCount[comment.commentId] ?? 0;
        final remaining = comment.childrenCount - visible;

        return Padding(
          padding: EdgeInsets.only(top: commentIndex == 0 ? 16 : 0),
          child: Stack(
            children: [
              // ===== THREAD LINES =====
              Positioned.fill(
                child: CustomPaint(
                  painter: _ThreadLinePainter(
                    depth: depth,
                    hasNextSibling: hasNextSibling,
                  ),
                ),
              ),

              // ===== COMMENT CARD =====
              CardComment(
                comment: comment,
                depth: depth,
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

  int _calculateDepth(CommentModel comment, List<CommentModel> flat) {
    int depth = 0;
    CommentModel? current = comment;

    while (current?.parentId != null) {
      depth++;
      try {
        current = flat.firstWhere((c) => c.commentId == current!.parentId);
      } catch (_) {
        break;
      }
    }
    return depth;
  }

  bool _hasNextSibling(List<CommentModel> flat, int index, int depth) {
    for (int i = index + 1; i < flat.length; i++) {
      final d = _calculateDepth(flat[i], flat);
      if (d == depth) return true;
      if (d < depth) return false;
    }
    return false;
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

      // vertical line
      if (hasNextSibling || i < depth - 1) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }

      // horizontal connector
      if (i == depth - 1) {
        canvas.drawLine(Offset(x, 24.0), Offset(x + 16.0, 24.0), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
