import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:LinkLian/core/utils/notification_navigation_helper.dart';
import 'package:LinkLian/core/services/notification/notification_payload.dart';
import 'package:LinkLian/core/services/notification/notification_service.dart';
import 'package:LinkLian/core/constants/colors.dart';

/// Wrap widget นี้ไว้รอบ GetMaterialApp เพื่อแสดง in-app banner อัตโนมัติ
/// ใช้ Stack overlay ใน widget tree แทน Get.rawSnackbar เพื่อให้ tap ทำงานได้
/// ไม่ขึ้นอยู่กับ navigator context ของ GetX
class NotificationBannerWrapper extends StatefulWidget {
  final Widget child;
  const NotificationBannerWrapper({super.key, required this.child});

  @override
  State<NotificationBannerWrapper> createState() =>
      _NotificationBannerWrapperState();
}

class _NotificationBannerWrapperState extends State<NotificationBannerWrapper> {
  final _service = NotificationService();

  NotificationPayload? _payload;
  Worker? _worker;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _worker = ever(_service.inAppNotification, (NotificationPayload? payload) {
      if (payload != null) _showBanner(payload);
    });
  }

  @override
  void dispose() {
    _worker?.dispose();
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _showBanner(NotificationPayload payload) {
    _dismissTimer?.cancel();
    setState(() => _payload = payload);

    _dismissTimer = Timer(const Duration(seconds: 4), _dismissBanner);
  }

  void _dismissBanner() {
    if (mounted) setState(() => _payload = null);
  }

  void _onTap() {
    _dismissTimer?.cancel();
    final payload = _payload;
    setState(() => _payload = null);
    if (payload != null) {
      NotificationNavigationHelper.navigate(payload);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_payload != null)
          _BannerOverlay(
            payload: _payload!,
            onTap: _onTap,
            onDismiss: _dismissBanner,
          ),
      ],
    );
  }
}

// ─── Banner overlay ───────────────────────────────────────────────────────────

class _BannerOverlay extends StatefulWidget {
  final NotificationPayload payload;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _BannerOverlay({
    required this.payload,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_BannerOverlay> createState() => _BannerOverlayState();
}

class _BannerOverlayState extends State<_BannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slide,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
              child: _BannerCard(payload: widget.payload),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Banner card ──────────────────────────────────────────────────────────────

class _BannerCard extends StatelessWidget {
  final NotificationPayload payload;
  const _BannerCard({required this.payload});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      color: _bgColor(payload.feature),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.notifications_rounded,
                color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    payload.title.isNotEmpty
                        ? payload.title
                        : payload.actorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    payload.body,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _bgColor(String feature) {
    switch (feature) {
      case 'social-feed':
        return AppColors.successPalette[600]!;
      case 'community':
        return AppColors.warningPalette[600]!;
      case 'qna':
        return AppColors.primaryPalette[600]!;
      case 'chat':
        return AppColors.buttonPalette[600]!;
      default:
        return AppColors.buttonPalette[500]!;
    }
  }
}
