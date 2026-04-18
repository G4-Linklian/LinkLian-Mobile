import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:LinkLian/core/constants/linklian-icon.dart';
import 'package:LinkLian/core/constants/colors.dart';
import '../../data/models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final isUnread = !n.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread ? AppColors.primaryPalette[100] : AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── ไอคอน feature + action badge ──
            _FeatureIcon(
              feature: n.feature,
              type: n.type,
              postType: n.notiData.postType,
            ),
            const SizedBox(width: 12),
            // ── เนื้อหา ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // บรรทัดที่ 1: ชื่อ class / community / บุคคล + inline badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          _getTitle(n),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildInlineBadge(n),
                    ],
                  ),
                  // บรรทัดที่ 2 (optional): ชื่อโพสต์ต้นทาง — แสดงเมื่อมี comment/reply
                  if (_getPostTitle(n).isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      _getPostTitle(n),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 2),
                  // Body: "[actorName] โพสต์/แสดงความคิดเห็น: [content]"
                  Text(
                    _getBody(n),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // เวลา
                  Text(
                    _timeAgo(n.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryPalette[900],
                    ),
                  ),
                ],
              ),
            ),
            // จุดแจ้งเตือนยังไม่อ่าน
            if (isUnread) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: _featureColor(n.feature),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Title ──────────────────────────────────────────────────────────────────

  String _getTitle(NotificationModel n) {
    if (n.feature == 'chat') return n.notiData.actorName;
    return n.notiData.title.isNotEmpty ? n.notiData.title : n.notiData.actorName;
  }

  String _getPostTitle(NotificationModel n) {
    if (n.feature == 'chat' || n.feature == 'assignment') return '';
    return n.notiData.postTitle ?? '';
  }

  // ── Body ───────────────────────────────────────────────────────────────────

  String _getBody(NotificationModel n) {
    final feature = n.feature;
    final type = n.type.toLowerCase();
    final data = n.notiData;

    switch (feature) {
      case 'chat':
        return data.body;
      case 'assignment':
        return data.body;
      case 'social-feed':
      case 'community':
      case 'qna':
        if (data.actorName.isEmpty) return data.body;
        return '${data.actorName} ${_actionVerb(type)}: ${data.body}';
      default:
        return data.body;
    }
  }

  String _actionVerb(String type) {
    if (type.contains('reply')) return 'ตอบกลับคอมเมนต์';
    if (type.contains('comment')) return 'แสดงความคิดเห็น';
    return 'โพสต์';
  }

  // ── Inline badge ──────────────────────────────────────────────────────────

  Widget _buildInlineBadge(NotificationModel n) {
    final type = n.type.toLowerCase();
    final postType = n.notiData.postType?.toLowerCase() ?? '';

    // Assignment deadline
    if (n.feature == 'assignment' && type.contains('deadline')) {
      final days = n.notiData.daysUntilDeadline;
      final label = (days != null && days > 0)
          ? 'ครบกำหนดในอีก $days วัน'
          : 'ครบกำหนดแล้ว';
      return _BadgePill(label: label, bgColor: AppColors.dangerPalette[500]!);
    }

    // Announcement post type
    if (postType == 'announcement' || type.contains('announcement')) {
      return _BadgePill(
        label: 'ประกาศ',
        bgColor: AppColors.buttonPalette[600]!,
      );
    }

    return const SizedBox.shrink();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาที';
    if (diff.inHours < 24) return '${diff.inHours} ชั่วโมง';
    if (diff.inDays < 7) return '${diff.inDays} วัน';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} สัปดาห์';
    return '${(diff.inDays / 30).floor()} เดือน';
  }
}

// ─── Inline badge pill ────────────────────────────────────────────────────────

class _BadgePill extends StatelessWidget {
  final String label;
  final Color bgColor;

  const _BadgePill({required this.label, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Feature icon ─────────────────────────────────────────────────────────────

class _FeatureIcon extends StatelessWidget {
  final String feature;
  final String type;
  final String? postType;

  const _FeatureIcon({
    required this.feature,
    required this.type,
    this.postType,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        children: [
          // วงกลมหลัก 46x46
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _mainBgColor(),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: _buildMainIcon(),
          ),
          // Action badge 20x20 มุมล่างขวา
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _badgeBgColor(),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Icon(
                _badgeIcon(),
                size: 11,
                color: AppColors.primaryPalette[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Main circle icon ──

  Widget _buildMainIcon() {
    switch (feature) {
      case 'chat':
        return HugeIcon(
          icon: HugeIcons.strokeRoundedMessage01,
          size: 22,
          color: AppColors.primaryPalette[900]!,
        );
      case 'social-feed':
      case 'community':
      case 'assignment':
        return _buildSocialPostIcon();
      case 'qna':
        return Icon(LinkLianIcon.notifQna, size: 22, color: AppColors.primaryPalette[900]);
      default:
        return Icon(LinkLianIcon.notifDefault, size: 22, color: AppColors.primaryPalette[900]);
    }
  }

  /// ไอคอน "การ์ดบทความ + วงคนโพสต์" — ตรงกับ Figma social feed
  Widget _buildSocialPostIcon() {
    return SizedBox(
      width: 26,
      height: 26,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // กล่องเอกสาร/บทความ (ล่าง-ซ้าย)
          Positioned(
            left: 0,
            bottom: 0,
            child: Icon(
              TablerIcons.notes,
              size: 21,
              color: AppColors.primaryPalette[900],
            ),
          ),
          // วงกลมคน (บน-ขวา)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryPalette[900]!, width: 1),
              ),
              child: Center(
                child: Icon(
                  TablerIcons.user,
                  size: 8,
                  color: AppColors.primaryPalette[900],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _mainBgColor() {
    switch (feature) {
      case 'chat':
        return AppColors.successPalette[500]!;
      case 'qna':
        return AppColors.buttonPalette[500]!;
      default:
        return AppColors.primaryPalette[400]!;
    }
  }

  // ── Action badge (bottom-right) ──

  /// icon สำหรับ badge มุมล่างขวา — เข้ารหัส action type หรือ post type
  IconData _badgeIcon() {
    final t = type.toLowerCase();
    final pt = (postType ?? '').toLowerCase();

    if (t.contains('deadline')) return LinkLianIcon.notifActionDeadline;
    if (t.contains('reply')) return LinkLianIcon.notifActionReply;
    if (t.contains('comment')) return LinkLianIcon.notifActionComment;
    if (pt == 'announcement' || t.contains('announcement')) {
      return LinkLianIcon.notifActionAnnouncement;
    }
    if (pt == 'question' || t.contains('question')) return LinkLianIcon.notifQna;
    if (pt == 'assignment' || t.contains('assignment')) {
      return LinkLianIcon.notifActionAssignment;
    }
    if (feature == 'chat') return LinkLianIcon.notifChat;
    // create post
    return TablerIcons.pencil_plus;
  }

  Color _badgeBgColor() => AppColors.primaryPalette[300]!;
}

// ─── Feature color (ใช้สำหรับ unread dot) ────────────────────────────────────

Color _featureColor(String feature) {
  switch (feature) {
    case 'social-feed':
    case 'community':
      return AppColors.primaryPalette[500]!;
    case 'chat':
      return AppColors.successPalette[500]!;
    case 'assignment':
      return AppColors.dangerPalette[500]!;
    case 'qna':
      return AppColors.buttonPalette[500]!;
    default:
      return AppColors.buttonPalette[400]!;
  }
}
