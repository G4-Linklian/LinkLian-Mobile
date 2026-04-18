import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:LinkLian/core/services/notification/notification_service.dart';
import 'package:LinkLian/core/utils/notification_navigation_helper.dart';
import 'package:LinkLian/core/services/notification/notification_payload.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationGroup {
  final String label;
  final List<NotificationModel> items;
  const NotificationGroup({required this.label, required this.items});
}

class NotificationController extends GetxController {
  final _repo = NotificationRepository();

  final notifications = <NotificationModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final unreadCount = 0.obs;

  int _offset = 0;
  static const _pageSize = 20;
  bool _hasMore = true;

  @override
  void onInit() {
    super.onInit();

    // ต้อง defer การเซต state ออกไปหลัง build frame ปัจจุบัน
    // เพราะ onInit() ถูกเรียกระหว่าง build phase ของ GetView
    // การเซต Rx value ตอนนั้นทำให้ Obx ใน widget อื่น rebuild ทับกัน
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().unreadCount.value = 0;
    });

    _loadThenMarkAllRead();

    // รีเฟรชเมื่อมี notification ใหม่เข้ามาจาก Socket
    ever(NotificationService().inAppNotification, (NotificationPayload? payload) {
      if (payload != null) {
        loadNotifications(refresh: true);
      }
    });
  }

  /// โหลด notification ก่อน แล้วค่อย mark all read
  /// เพื่อให้ badge หายทันที แต่ UI ยังแสดงสถานะถูกต้อง
  Future<void> _loadThenMarkAllRead() async {
    await loadNotifications();
    await markAllAsRead();
  }

  Future<void> loadNotifications({bool refresh = false}) async {
    if (refresh) {
      _offset = 0;
      _hasMore = true;
    }

    if (isLoading.value) return;
    isLoading.value = true;

    try {
      final result = await _repo.getNotifications(offset: 0, limit: _pageSize);
      _offset = result.notifications.length;
      _hasMore = result.notifications.length < result.total;
      notifications.assignAll(result.notifications);
    } catch (e) {
      Get.snackbar('เกิดข้อผิดพลาด', 'ไม่สามารถโหลดการแจ้งเตือนได้',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !_hasMore) return;
    isLoadingMore.value = true;

    try {
      final result = await _repo.getNotifications(offset: _offset, limit: _pageSize);
      _offset += result.notifications.length;
      _hasMore = _offset < result.total;
      notifications.addAll(result.notifications);
    } catch (_) {
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> onTapNotification(NotificationModel n) async {
    if (!n.isRead) {
      await _repo.markAsRead(n.notificationId);
      final idx = notifications.indexWhere((e) => e.notificationId == n.notificationId);
      if (idx != -1) {
        notifications[idx] = n.copyWith(isRead: true);
      }
      if (unreadCount.value > 0) unreadCount.value--;
    }

    // ปิดหน้าแจ้งเตือนก่อน navigate เสมอ
    Get.back();

    NotificationNavigationHelper.navigate(
      NotificationPayload(
        notificationId: n.notificationId.toString(),
        receiveUserId: '',
        actorId: n.actorId.toString(),
        actorName: n.notiData.actorName,
        title: n.notiData.title,
        body: n.notiData.body,
        refId: n.notiData.refId,
        refType: n.notiData.refType,
        feature: n.feature,
        sectionId: n.notiData.sectionId,
        communityId: n.notiData.communityId,
      ),
    );
  }

  Future<void> markAllAsRead() async {
    await _repo.markAllAsRead();
    final updated = notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifications.assignAll(updated);
    unreadCount.value = 0;
  }

  // ─── Grouping ────────────────────────────────────────────────────────────────

  List<NotificationGroup> get grouped {
    final now = DateTime.now();
    final Map<String, List<NotificationModel>> buckets = {
      'ล่าสุด': [],
      '7 วันที่แล้ว': [],
      'เดือนที่แล้ว': [],
      'เก่ากว่านั้น': [],
    };

    for (final n in notifications) {
      final diff = now.difference(n.createdAt);
      if (diff.inHours < 24) {
        buckets['ล่าสุด']!.add(n);
      } else if (diff.inDays < 7) {
        buckets['7 วันที่แล้ว']!.add(n);
      } else if (diff.inDays < 30) {
        buckets['เดือนที่แล้ว']!.add(n);
      } else {
        buckets['เก่ากว่านั้น']!.add(n);
      }
    }

    return buckets.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => NotificationGroup(label: e.key, items: e.value))
        .toList();
  }
}
