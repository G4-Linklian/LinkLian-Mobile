import 'package:flutter/material.dart';
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
        color: isUnread ? AppColors.primaryPalette[300] : AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + Feature badge
            _Avatar(actorName: n.notiData.actorName, feature: n.feature),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          n.notiData.actorName,
                          style: TextStyle(
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.primaryPalette[900],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timeAgo(n.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.buttonPalette[400],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    n.notiData.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: isUnread
                          ? AppColors.primaryPalette[900]
                          : AppColors.buttonPalette[300],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
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

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาที';
    if (diff.inHours < 24) return '${diff.inHours} ชั่วโมง';
    if (diff.inDays < 7) return '${diff.inDays} วัน';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} สัปดาห์';
    return '${(diff.inDays / 30).floor()} เดือน';
  }
}

// ─── Avatar with feature badge ────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String actorName;
  final String feature;

  const _Avatar({required this.actorName, required this.feature});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        children: [
          // Main avatar circle
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _avatarBg(actorName),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(actorName),
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          // Feature badge
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: _featureColor(feature),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryPalette[900]!, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Icon(
                _featureIcon(feature),
                size: 10,
                color: AppColors.primaryPalette[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Color _avatarBg(String name) {
    const colors = [
      AppColors.primaryPalette,
      AppColors.successPalette,
      AppColors.warningPalette,
      AppColors.dangerPalette,
      AppColors.buttonPalette,
    ];
    final hash = name.codeUnits.fold(0, (a, b) => a + b);
    final paletteIndex = hash % colors.length;
    return colors[paletteIndex][500]!;
  }
}

Color _featureColor(String feature) {
  switch (feature) {
    case 'social-feed':
      return AppColors.successPalette[500]!; // green
    case 'community':
      return AppColors.warningPalette[500]!; // orange
    case 'qna':
      return AppColors.primaryPalette[500]!; // orange
    case 'chat':
      return AppColors.buttonPalette[500]!; // blue
    default:
      return AppColors.buttonPalette[400]!; // gray
  }
}

IconData _featureIcon(String feature) {
  switch (feature) {
    case 'social-feed':
      return LinkLianIcon.notifSocialFeed;
    case 'community':
      return LinkLianIcon.notifCommunity;
    case 'qna':
      return LinkLianIcon.notifQna;
    case 'chat':
      return LinkLianIcon.notifChat;
    default:
      return LinkLianIcon.notifDefault;
  }
}
