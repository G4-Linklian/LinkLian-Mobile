import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:LinkLian/core/constants/linklian-icon.dart';
import '../controllers/notification_controller.dart';
import '../widgets/notification_card.dart';

class NotificationPage extends GetView<NotificationController> {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LinkLianIcon.back, color: Color(0xFF1E293B)),
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
        title: const Text(
          'การแจ้งเตือน',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: [
          Obx(() {
            if (controller.unreadCount.value == 0) return const SizedBox.shrink();
            return TextButton(
              onPressed: controller.markAllAsRead,
              child: const Text(
                'อ่านทั้งหมด',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.notifications.isEmpty) {
          return _EmptyState();
        }

        final groups = controller.grouped;

        return RefreshIndicator(
          onRefresh: () => controller.loadNotifications(refresh: true),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _itemCount(groups, controller.isLoadingMore.value),
            itemBuilder: (context, index) {
              return _buildItem(context, index, groups, controller);
            },
          ),
        );
      }),
    );
  }

  int _itemCount(List groups, bool isLoadingMore) {
    // Each group = 1 header + N items
    int count = groups.fold<int>(0, (sum, g) => sum + 1 + (g.items as List).length);
    if (isLoadingMore) count++;
    return count;
  }

  Widget _buildItem(
    BuildContext context,
    int index,
    List groups,
    NotificationController ctrl,
  ) {
    int cursor = 0;
    for (final group in groups) {
      if (index == cursor) {
        return _GroupHeader(label: group.label);
      }
      cursor++;
      final items = group.items as List;
      if (index < cursor + items.length) {
        final n = items[index - cursor];
        return Column(
          children: [
            NotificationCard(
              notification: n,
              onTap: () => ctrl.onTapNotification(n),
            ),
            const Divider(height: 1, indent: 76, endIndent: 16, color: Color(0xFFE2E8F0)),
          ],
        );
      }
      cursor += items.length;
    }

    // Loading more indicator
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

// ─── Group header ─────────────────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  final String label;
  const _GroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      color: const Color(0xFFF8FAFC),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF64748B),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LinkLianIcon.notification,
            size: 56,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'ยังไม่มีการแจ้งเตือน',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
