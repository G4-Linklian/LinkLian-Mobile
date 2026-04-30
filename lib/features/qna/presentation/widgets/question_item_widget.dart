import 'package:LinkLian/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class QuestionItemWidget extends StatelessWidget {
  final dynamic question;
  final bool isUpvoted;
  final int upvoteCount;
  final bool isLocalPending;
  final bool readOnly;
  final bool isHistoryMode;
  final VoidCallback onUpvote;
  final Function(int?)? onReply;

  const QuestionItemWidget({
    super.key,
    required this.question,
    required this.isUpvoted,
    required this.upvoteCount,
    required this.isLocalPending,
    required this.readOnly,
    required this.onUpvote,
    this.onReply,
    this.isHistoryMode = false,
  });

  String _sanitizeText(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null' || text == '-') {
      return '';
    }
    return text;
  }

  bool _isTruthy(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  String _formatTime(dynamic value) {
    DateTime? dateTime;

    if (value is DateTime) {
      dateTime = value;
    } else if (value is String && value.trim().isNotEmpty) {
      dateTime = DateTime.tryParse(value);
    }

    if (dateTime == null) {
      return 'เมื่อสักครู่';
    }

    final localDateTime = dateTime.toLocal();
    final diff = DateTime.now().difference(localDateTime);
    if (diff.inMinutes < 1) return 'เมื่อสักครู่';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';

    return '${localDateTime.day}/${localDateTime.month}/${localDateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    final slideNumber = question['slide_number'];
    final asker = question['asker'];
    final askerMap = asker is Map
        ? Map<String, dynamic>.from(asker)
        : <String, dynamic>{};
    final askerName = _resolveName(askerMap);
    final askerAvatar = _resolveAvatar(askerMap);
    final createdAt = _formatTime(question['created_at']);
    final status = question['status']?.toString()?.toUpperCase() ?? '';
    final isAnswered =
        status == 'ANSWERED' || status == 'RESOLVED' || status == 'DONE';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryPalette[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryPalette[200],
                foregroundImage: askerAvatar != null && askerAvatar.isNotEmpty
                    ? NetworkImage(askerAvatar)
                    : null,
                child: askerAvatar == null || askerAvatar.isEmpty
                    ? Icon(
                        Icons.person,
                        size: 20,
                        color: AppColors.primaryPalette[400],
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            askerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            if (isAnswered && !isHistoryMode) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.successPalette[700],
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'ตอบแล้ว',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            Text(
                              createdAt,
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                color: AppColors.primaryPalette[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question['question']?.toString() ?? '',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (slideNumber != null && slideNumber.toString().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPalette[100],
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'หน้า $slideNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.primaryPalette[700],
                    ),
                  ),
                ),
              const Spacer(),
              if (isLocalPending) ...[
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 6),
                const Text('กำลังส่ง...'),
              ] else ...[
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: !readOnly ? onUpvote : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isUpvoted
                          ? AppColors.primaryPalette[100]
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          TablerIcons.arrow_big_up_lines,
                          size: 18,
                          color: isUpvoted
                              ? const Color(0xFFF97316)
                              : const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'โหวต',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isUpvoted
                                ? const Color(0xFFF97316)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                        if (upvoteCount > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '$upvoteCount',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isUpvoted
                                  ? const Color(0xFFF97316)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                TextButton(
                  onPressed:
                      slideNumber != null && slideNumber.toString().isNotEmpty
                      ? () {
                          onReply?.call(slideNumber);
                        }
                      : null,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        TablerIcons.arrow_forward,
                        size: 16,
                        color: AppColors.primaryPalette[600],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'ไปที่หน้านี้',
                        style: TextStyle(color: AppColors.primaryPalette[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _resolveName(Map<String, dynamic> askerMap) {
    final firstName = _sanitizeText(askerMap['first_name']);
    final lastName = _sanitizeText(askerMap['last_name']);

    final fullName = [
      firstName,
      lastName,
    ].where((e) => e.isNotEmpty).join(' ').trim();

    if (fullName.isNotEmpty) {
      return fullName;
    }

    final isAnonymous =
        _isTruthy(question['is_anonymous']) ||
        _isTruthy(askerMap['is_anonymous']);

    return isAnonymous ? 'ผู้ใช้ไม่ระบุตัวตน' : 'ผู้ใช้ทั่วไป';
  }

  String? _resolveAvatar(Map<String, dynamic> askerMap) {
    final avatar = _sanitizeText(askerMap['profile_pic']);
    if (avatar.isNotEmpty) return avatar;
    return null;
  }
}
