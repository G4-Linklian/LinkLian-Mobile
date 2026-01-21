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
          icon: const Icon(
            LinkLianIcon.back,
            color: AppColors.black,
            size: 24,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // ===== POST =====
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm,
            ),
            child: CardPost(
              post: controller.post,
              onSelectForAI: null,
            ),
          ),

          Container(height: 8, color: const Color(0xFFF5F5F5)),

          // ===== COMMENTS =====
          Expanded(
            child: Obx(() => _buildCommentList(controller)),
          ),

          // ===== INPUT =====
          CommentInputBar(controller: controller),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN LIST
  // ============================================================

  Widget _buildCommentList(CommentController controller) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.flatComments.isEmpty) {
      return _buildEmptyState();
    }

    final flat = controller.flatComments;

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16),
      itemCount: flat.length,
      itemBuilder: (context, index) {
        final comment = flat[index];
        final depth = _calculateDepth(comment, flat);
        final hasNextSibling =
            _hasNextSibling(flat, index, depth);
                final visible =
    controller.visibleChildrenCount[comment.commentId] ?? 0;

final remaining =
    comment.childrenCount - visible;

        return Stack(
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
)
          ],
        );
      },
    );
  }

  // ============================================================
  // DEPTH & THREAD HELPERS
  // ============================================================

  int _calculateDepth(
    CommentModel comment,
    List<CommentModel> flat,
  ) {
    int depth = 0;
    CommentModel? current = comment;

    while (current?.parentId != null) {
      depth++;
      try {
        current = flat.firstWhere(
          (c) => c.commentId == current!.parentId,
        );
      } catch (_) {
        break;
      }
    }
    return depth;
  }

  bool _hasNextSibling(
    List<CommentModel> flat,
    int index,
    int depth,
  ) {
    for (int i = index + 1; i < flat.length; i++) {
      final d = _calculateDepth(flat[i], flat);
      if (d == depth) return true;
      if (d < depth) return false;
    }
    return false;
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 64, color: Colors.grey.shade300),
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

// ============================================================
// THREAD LINE PAINTER (Facebook style)
// ============================================================

class _ThreadLinePainter extends CustomPainter {
  final int depth;
  final bool hasNextSibling;

  _ThreadLinePainter({
    required this.depth,
    required this.hasNextSibling,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    for (int i = 0; i < depth; i++) {
      final double x = 16.0 + i * 32.0 + 10.0;

      // vertical line
      if (hasNextSibling || i < depth - 1) {
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height),
          paint,
        );
      }

      // horizontal connector
      if (i == depth - 1) {
        canvas.drawLine(
          Offset(x, 24.0),
          Offset(x + 16.0, 24.0),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}