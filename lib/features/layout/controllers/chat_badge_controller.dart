import 'package:get/get.dart';
import '../../chat/presentation/controllers/chat.controller.dart';

class ChatBadgeController extends GetxController {
  var unreadCount = 0.obs;

  Future<void> fetchUnreadCount() async {
    final chats = await ChatController().getChat();
    int total = 0;
    for (final chat in chats) {
      if (chat.unreadCount != null) {
        total += chat.unreadCount!;
      }
    }
    unreadCount.value = total;
  }
}
