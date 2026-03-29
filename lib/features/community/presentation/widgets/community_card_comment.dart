import 'package:LinkLian/core/constants/linklian-icon.dart';
import 'package:flutter/material.dart';
import '../../data/models/community_comment_model.dart';
import '../../../../core/constants/colors.dart';

class CardCommentCommunity extends StatelessWidget {
  final CommunityCommentModel comment;
  final int depth;
  final VoidCallback? onReply;
  final VoidCallback? onShowMore;
  final int? remainingReplies;
  final int currentUserId;

  const CardCommentCommunity({
    super.key,
    required this.comment,
    required this.depth,
    this.onReply,
    this.onShowMore,
    this.remainingReplies,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final isDeletedUser =
        comment.displayName == null || comment.displayName!.trim().isEmpty;
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        isDeletedUser
                            ? 'ไม่มีบัญชีผู้ใช้งาน'
                            : comment.displayName!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(width: 4),

                    Text(
                      _formatTime(comment.createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),

                const SizedBox(height: 4),
                Text(comment.commentText),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onReply,
                      child: Text(
                        'ตอบกลับ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryPalette[600],
                        ),
                      ),
                    ),
                    if (onShowMore != null && (remainingReplies ?? 0) > 0) ...[
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
    final isDeletedUser = comment.displayName == 'ไม่มีบัญชีผู้ใช้งาน';

    return CircleAvatar(
      radius: 20,

      backgroundColor: isDeletedUser
          ? Colors.grey[300]
          : AppColors.primaryPalette[200],

      backgroundImage:
          (!isDeletedUser &&
              comment.profilePic != null &&
              comment.profilePic!.isNotEmpty)
          ? NetworkImage(comment.profilePic!)
          : null,

      // child: isDeletedUser
      //     ? Icon(LinkLianIcon.useroff, color: Colors.grey[600], size: 20)
      //     : (comment.profilePic == null || comment.profilePic!.isEmpty
      //           ? Icon(
      //               //LinkLianIcon.identifiedUser,
      //               LinkLianIcon.useroff,
      //               color: AppColors.primaryPalette[600],
      //               size: 18,
      //             )
      child: isDeletedUser
          ? Icon(LinkLianIcon.useroff, color: Colors.grey[600], size: 20)
          : (comment.profilePic == null || comment.profilePic!.isEmpty
                ? Text(
                    _getInitials(comment.displayName ?? ''),
                    style: TextStyle(
                      color: AppColors.primaryPalette[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null),
      //           : null),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final parts = name.trim().split(' ');

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String _formatTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'เมื่อสักครู่';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
