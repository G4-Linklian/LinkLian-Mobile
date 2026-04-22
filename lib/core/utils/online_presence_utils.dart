import 'dart:async';

import 'package:LinkLian/core/services/socket_service.dart';
import 'package:LinkLian/core/utils/logger.dart';
import 'package:flutter/foundation.dart';

class OnlinePresenceUtils {
  static final ValueNotifier<Map<int, bool>> onlineStatuses =
      ValueNotifier<Map<int, bool>>(<int, bool>{});
  static StreamSubscription<dynamic>? _onlineStreamSubscription;

  static Set<int> toUniqueUserIdSet(Iterable<int?> ids) {
    return ids.whereType<int>().where((id) => id > 0).toSet();
  }

  static void ensureOnlineStreamBinding({SocketService? socketService}) {
    if (_onlineStreamSubscription != null) {
      return;
    }

    final service = socketService ?? SocketService();
    _onlineStreamSubscription = service.onlineStream.listen(_handleOnlineEvent);
  }

  static bool subscribeOnlineStatus({
    required SocketService socketService,
    required Iterable<int?> userSysIds,
  }) {
    ensureOnlineStreamBinding(socketService: socketService);

    final ids = toUniqueUserIdSet(userSysIds);
    appLog.info('Subscribing to online status for user_sys_ids: $ids');
    if (ids.isEmpty) {
      return false;
    }

    return socketService.subscribeOnlineStatus(userSysIds: ids);
  }

  static bool isOnline(int? userSysId) {
    if (userSysId == null) {
      return false;
    }
    return onlineStatuses.value[userSysId] ?? false;
  }

  static void _handleOnlineEvent(dynamic event) {
    if (event is! Map) {
      return;
    }

    final type = event['type']?.toString();
    final payload = event['payload'];

    if (type == 'ONLINE_SUBSCRIPTION_RESULT' || type == 'ONLINE_STATUS_RESULT') {
      final statuses = parseStatuses(payload?['statuses']);
      if (statuses.isEmpty) {
        return;
      }

      final merged = Map<int, bool>.from(onlineStatuses.value)
        ..addAll(statuses);
      onlineStatuses.value = merged;
      return;
    }

    if (type == 'ONLINE_PRESENCE_CHANGED') {
      final userId = parseUserSysId(payload?['user_sys_id']);
      if (userId == null) {
        return;
      }

      final updated = Map<int, bool>.from(onlineStatuses.value)
        ..[userId] = parseOnlineFlag(payload?['is_online']);
      onlineStatuses.value = updated;
    }
  }

  static int? parseUserSysId(dynamic raw) {
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  static bool parseOnlineFlag(dynamic raw) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final normalized = raw.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  static Map<int, bool> parseStatuses(dynamic statusesRaw) {
    if (statusesRaw is! Map) {
      return <int, bool>{};
    }

    final parsed = <int, bool>{};
    statusesRaw.forEach((key, value) {
      final userId = parseUserSysId(key);
      if (userId != null) {
        parsed[userId] = parseOnlineFlag(value);
      }
    });
    return parsed;
  }
}
