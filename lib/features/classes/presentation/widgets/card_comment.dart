import 'package:flutter/material.dart';
import '../../data/models/comment_model.dart';
import '../../../../core/constants/colors.dart';

class CardComment extends StatelessWidget {
  final CommentModel comment;
  final int depth;
  final VoidCallback? onReply;
  final VoidCallback? onShowMore;
  final int? remainingReplies;
  final bool disableReply;

  const CardComment({
    super.key,
    required this.comment,
    required this.depth,
    this.onReply,
    this.onShowMore,
    this.remainingReplies,
    this.disableReply = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16.0 + depth * 32.0,
        right: 16,
        bottom: 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== HEADER =====
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.displayName ?? 'Anonymous',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      _formatTime(comment.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),
                Text(comment.commentText),

                const SizedBox(height: 8),

                // ===== ACTIONS =====
                Row(
                  children: [
                    GestureDetector(
                      onTap: disableReply ? null : onReply,
                      child: Text(
                        'ตอบกลับ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: disableReply
                              ? Colors.grey[400]
                              : AppColors.primaryPalette[600],
                        ),
                      ),
                    ),

                    if (onShowMore != null &&
                        (remainingReplies ?? 0) > 0) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onShowMore,
                        child: Text(
                          'ดูอีก $remainingReplies การตอบกลับ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryPalette[600],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.primaryPalette[200],
      foregroundImage: (!comment.isAnonymous &&
              comment.profilePic != null &&
              comment.profilePic!.isNotEmpty)
          ? NetworkImage(comment.profilePic!)
          : null,
      child: (comment.isAnonymous ||
              comment.profilePic == null ||
              comment.profilePic!.isEmpty)
          ? Icon(Icons.person,
              color: AppColors.primaryPalette[600])
          : null,
    );
  }
}

  // TIME FORMAT

  String _formatTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'เมื่อสักครู่';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

