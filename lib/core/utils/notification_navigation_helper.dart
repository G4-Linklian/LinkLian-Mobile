import 'package:get/get.dart';
import 'package:LinkLian/config/app_routes.dart';
import 'package:LinkLian/core/services/notification/notification_payload.dart';
import 'package:LinkLian/core/utils/logger.dart';
import 'package:LinkLian/features/chat/presentation/pages/chat.page.dart';
import 'package:LinkLian/features/layout/controllers/navigation_controller.dart';

/// Navigate ตาม ref_type ของ notification
/// เพิ่ม ref_type ใหม่ได้โดยเพิ่ม entry ใน _handlers เพียงอย่างเดียว
final Map<String, _NotificationHandler> _handlers = {
  'feed-post':         _FeedPostHandler(),
  'feed-comment':      _FeedPostHandler(), // reply → navigate ไปหน้า post เดียวกัน
  'community-post':    _CommunityPostHandler(),
  'community-comment': _CommunityPostHandler(),
  'community':         _CommunityHandler(),
  'qna-live':          _QnaLiveHandler(),
  'qna-question':      _QnaQuestionHandler(),
  'chat':              _ChatHandler(),
};

class NotificationNavigationHelper {
  static void navigate(NotificationPayload payload) {
    Get.closeAllSnackbars();

    appLog.debug('NotifNav payload', data: {
      'refType': payload.refType,
      'refId': payload.refId,
      'sectionId': payload.sectionId,
      'communityId': payload.communityId,
      'feature': payload.feature,
    });

    final handler = _handlers[payload.refType];
    if (handler != null) {
      handler.navigate(payload);
    } else {
      appLog.warning('No handler for refType: ${payload.refType}');
    }
  }
}

// ─── Handler Interface ────────────────────────────────────────────────────────

abstract class _NotificationHandler {
  void navigate(NotificationPayload payload);
}

// ─── Handlers ─────────────────────────────────────────────────────────────────

class _FeedPostHandler implements _NotificationHandler {
  @override
  void navigate(NotificationPayload payload) {
    final nav = Get.find<NavigationController>();
    // ใช้ sectionId ที่ backend ส่งมาแยก — refId คือ post_content_id (ไม่ใช่ section)
    final sectionId = int.tryParse(payload.sectionId ?? '');
    if (sectionId == null) {
      // sectionId ยังไม่มี (notification เก่า) → ไปที่ tab ห้องเรียนเป็น fallback
      nav.changeTab(1);
      return;
    }

    nav.showClassDetailFromRedirect({
      'sectionId': sectionId,
      // refId = post_content_id — ใช้ scroll ไปหาโพสต์นั้น
      'highlightPostId': int.tryParse(payload.refId),
    });
  }
}

class _CommunityPostHandler implements _NotificationHandler {
  @override
  void navigate(NotificationPayload payload) {
    final nav = Get.find<NavigationController>();
    // ใช้ communityId ที่ backend ส่งมาแยก — refId คือ post_id (ไม่ใช่ community)
    final communityId = int.tryParse(payload.communityId ?? '');
    if (communityId == null) {
      // communityId ยังไม่มี (notification เก่า) → ไปที่ tab ชุมชนเป็น fallback
      nav.changeTab(2);
      return;
    }

    nav.showCommunityDetailFromRedirect({'communityId': communityId});
  }
}

class _CommunityHandler implements _NotificationHandler {
  @override
  void navigate(NotificationPayload payload) {
    final nav = Get.find<NavigationController>();
    // ref_type = 'community' ส่ง community_id เป็น refId ตรง ๆ อยู่แล้ว
    final communityId = int.tryParse(payload.refId);
    if (communityId == null) {
      nav.changeTab(2);
      return;
    }

    nav.showCommunityDetailFromRedirect({'communityId': communityId});
  }
}

class _QnaLiveHandler implements _NotificationHandler {
  @override
  void navigate(NotificationPayload payload) {
    Get.toNamed(
      AppRoutes.qnaLive,
      arguments: {'qa_live_id': payload.refId},
    );
  }
}

class _QnaQuestionHandler implements _NotificationHandler {
  @override
  void navigate(NotificationPayload payload) {
    Get.toNamed(
      AppRoutes.qnaLive,
      arguments: {'qa_question_id': payload.refId},
    );
  }
}

class _ChatHandler implements _NotificationHandler {
  @override
  void navigate(NotificationPayload payload) {
    final chatId = int.tryParse(payload.refId);
    if (chatId == null) return;

    // Set pending chat ID so ChatPage auto-opens the correct conversation
    final nav = Get.find<NavigationController>();
    nav.pendingChatId.value = chatId;

    // ChatPage is pushed via Navigator (not a tab), same as AppBar chat icon
    Get.to(() => const ChatPage());
  }
}
