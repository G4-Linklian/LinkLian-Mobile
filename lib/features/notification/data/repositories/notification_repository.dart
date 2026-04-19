import 'package:LinkLian/core/services/api_client.dart';
import '../models/notification_model.dart';

class NotificationListResult {
  final List<NotificationModel> notifications;
  final int total;

  const NotificationListResult({
    required this.notifications,
    required this.total,
  });
}

class NotificationRepository {
  final ApiClient _api = ApiClient();

  Future<NotificationListResult> getNotifications({
    int offset = 0,
    int limit = 20,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/notification',
      queryParameters: {'offset': offset, 'limit': limit},
    );

    final data = res.data?['data'];
    if (data == null) return const NotificationListResult(notifications: [], total: 0);

    final rawList = data['notifications'] as List? ?? [];
    final notifications = rawList
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();

    return NotificationListResult(
      notifications: notifications,
      total: int.tryParse(data['total']?.toString() ?? '0') ?? 0,
    );
  }

  Future<int> getUnreadCount() async {
    final res = await _api.get<Map<String, dynamic>>('/notification/unread-count');
    final data = res.data?['data'];
    return int.tryParse(data?['unread_count']?.toString() ?? '0') ?? 0;
  }

  Future<void> markAsRead(int notificationId) async {
    await _api.patch('/notification/$notificationId/read', data: {});
  }

  Future<void> markAllAsRead() async {
    await _api.patch('/notification/read-all', data: {});
  }
}
