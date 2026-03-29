import 'package:LinkLian/features/chat/presentation/pages/ai_chat_detail.page.dart';
import 'package:LinkLian/core/utils/dialog_helper.dart';
import 'package:get/get.dart';

class AISummaryNotificationService {
  static bool _isAIChatDetailVisible = false;
  static int? _visibleAiChatId;

  static final Map<int, Map<String, String>> _pendingReplies = {};

  static void savePendingReply(int aiChatId, String question, String answer) {
    _pendingReplies[aiChatId] = {'question': question, 'answer': answer};
  }

  static Map<String, String>? consumePendingReply(int aiChatId) {
    return _pendingReplies.remove(aiChatId);
  }

  static void setAIChatDetailVisible(bool isVisible, {int? aiChatId}) {
    _isAIChatDetailVisible = isVisible;
    _visibleAiChatId = isVisible ? aiChatId : null;
  }

  static void updateVisibleAiChatId(int? aiChatId) {
    if (!_isAIChatDetailVisible) return;
    _visibleAiChatId = aiChatId;
  }

  static void _openAiChat({
    required int aiChatId,
    required String documentTitle,
    required String postTitle,
    required String summary,
    required String content,
    required List<Map<String, dynamic>> attachments,
    required int postContentId,
  }) {
    Get.closeCurrentSnackbar();

    if (_isAIChatDetailVisible && _visibleAiChatId == aiChatId) {
      return;
    }

    Get.to(
      () => AIChatDetailPage(
        title: postTitle,
        documentTitle: documentTitle,
        aiChatId: aiChatId,
        summary: summary,
        content: content,
        attachments: attachments,
        postContentId: postContentId,
      ),
    );
  }

  static void watchSummary({
    required Future<Map<String, dynamic>> summaryFuture,
    required int postContentId,
    required String fallbackPostTitle,
    required String content,
    required List<Map<String, dynamic>> attachments,
  }) {
    summaryFuture
        .then((result) {
          if (_isAIChatDetailVisible) {
            return;
          }

          final summary = _extractSummary(result).trim();
          final aiChatId = _extractAiChatId(result);
          final documentTitle = _extractDocumentTitle(result);
          final postTitle = _extractPostTitle(result);

          if (summary.isEmpty) {
            return;
          }

          void openSummaryChat() {
            Get.closeCurrentSnackbar();
            Get.to(
              () => AIChatDetailPage(
                title: postTitle.isNotEmpty ? postTitle : fallbackPostTitle,
                documentTitle: documentTitle.isNotEmpty
                    ? documentTitle
                    : 'AI Chat',
                aiChatId: aiChatId,
                summary: summary,
                content: content,
                attachments: attachments,
                postContentId: postContentId,
              ),
            );
          }

          DialogHelper.showNotification(
            title: 'AI สรุปเสร็จแล้ว',
            message: postTitle.isNotEmpty ? postTitle : fallbackPostTitle,
            type: NotificationType.success,
            titleSize: 16,
            duration: const Duration(seconds: 3),
            compact: true,
            onTap: openSummaryChat,
          );
        })
        .catchError((_) {
          if (_isAIChatDetailVisible) {
            return;
          }

          DialogHelper.showNotification(
            title: 'สรุปไม่สำเร็จ',
            message: 'กรุณาลองใหม่อีกครั้ง',
            type: NotificationType.error,
            titleSize: 16,
            duration: const Duration(seconds: 1),
            compact: true,
          );
        });
  }

  static void notifyAiReply({
    required int aiChatId,
    required String documentTitle,
    required String postTitle,
    required String summary,
    required String content,
    required List<Map<String, dynamic>> attachments,
    required int postContentId,
    required String question,
  }) {
    final preview = question.trim();
    if (preview.isEmpty) return;

    void openChat() {
      _openAiChat(
        aiChatId: aiChatId,
        documentTitle: documentTitle,
        postTitle: postTitle,
        summary: summary,
        content: content,
        attachments: attachments,
        postContentId: postContentId,
      );
    }

    DialogHelper.showNotification(
      title: 'AI ตอบกลับแล้ว',
      message: preview,
      type: NotificationType.success,
      titleSize: 16,
      duration: const Duration(seconds: 4),
      compact: true,
      onTap: openChat,
    );
  }

  static void notifySummaryCompleted({
    required int aiChatId,
    required String documentTitle,
    required String postTitle,
    required String summary,
    required String content,
    required List<Map<String, dynamic>> attachments,
    required int postContentId,
  }) {
    if (_isAIChatDetailVisible &&
        _visibleAiChatId == aiChatId &&
        aiChatId > 0) {
      return;
    }

    final message = postTitle.trim().isNotEmpty
        ? postTitle.trim()
        : documentTitle.trim();

    DialogHelper.showNotification(
      title: 'สรุปเนื้อหาเสร็จแล้ว',
      message: message.isNotEmpty ? message : 'AI Chat',
      type: NotificationType.success,
      titleSize: 16,
      duration: const Duration(seconds: 3),
      compact: true,
      onTap: () {
        _openAiChat(
          aiChatId: aiChatId,
          documentTitle: documentTitle,
          postTitle: postTitle,
          summary: summary,
          content: content,
          attachments: attachments,
          postContentId: postContentId,
        );
      },
    );
  }

  static void notifyQuizGenerated({
    required int aiChatId,
    required String documentTitle,
    required String postTitle,
    required String summary,
    required String content,
    required List<Map<String, dynamic>> attachments,
    required int postContentId,
    required String mode,
  }) {
    if (_isAIChatDetailVisible &&
        _visibleAiChatId == aiChatId &&
        aiChatId > 0) {
      return;
    }

    final isLearning = mode == 'learning';

    DialogHelper.showNotification(
      title: isLearning ? 'สร้างแบบการเรียนรู้สำเร็จ' : 'สร้างแบบทดสอบสำเร็จ',
      message: postTitle.trim().isNotEmpty
          ? postTitle.trim()
          : (documentTitle.trim().isNotEmpty
                ? documentTitle.trim()
                : 'AI Chat'),
      type: NotificationType.success,
      titleSize: 16,
      duration: const Duration(seconds: 3),
      compact: true,
      onTap: () {
        _openAiChat(
          aiChatId: aiChatId,
          documentTitle: documentTitle,
          postTitle: postTitle,
          summary: summary,
          content: content,
          attachments: attachments,
          postContentId: postContentId,
        );
      },
    );
  }

  static void notifySummaryCompletedInChat() {
    DialogHelper.showNotification(
      title: 'สรุปเนื้อหาเสร็จแล้ว',
      message: 'สามารถเริ่มอ่านและถามต่อได้ทันที',
      type: NotificationType.success,
      titleSize: 16,
      duration: const Duration(seconds: 2),
      compact: true,
    );
  }

  static void notifyQuizGeneratedInChat({required String mode}) {
    final isLearning = mode == 'learning';
    DialogHelper.showNotification(
      title: isLearning ? 'สร้างแบบการเรียนรู้สำเร็จ' : 'สร้างแบบทดสอบสำเร็จ',
      message: isLearning
          ? 'กดเข้าไปทำและดูเฉลยได้ทันที'
          : 'กดเข้าไปทำแบบทดสอบได้เลย',
      type: NotificationType.success,
      titleSize: 16,
      duration: const Duration(seconds: 2),
      compact: true,
    );
  }

  static String _extractSummary(Map<String, dynamic> result) {
    return (result['summary'] ??
            result['data']?['final_summary'] ??
            result['final_summary'] ??
            '')
        .toString();
  }

  static int _extractAiChatId(Map<String, dynamic> result) {
    final raw = result['ai_chat_id'];
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  static String _extractDocumentTitle(Map<String, dynamic> result) {
    return (result['document_title'] ??
            result['chat_title'] ??
            result['title'] ??
            '')
        .toString()
        .trim();
  }

  static String _extractPostTitle(Map<String, dynamic> result) {
    return (result['post_title'] ?? result['postTitle'] ?? '')
        .toString()
        .trim();
  }
}
