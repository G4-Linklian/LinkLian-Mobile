import 'package:get/get.dart';
import '../../chat/presentation/controllers/chat.controller.dart';

class ChatBadgeController extends GetxController {
  var unreadCount = 0.obs;

  Future<void> fetchUnreadCount() async {
  final chatController = Get.find<ChatController>();
  final chats = await chatController.getChat();

  unreadCount.value =
      chats.fold(0, (sum, chat) => sum + (chat.unreadCount ?? 0));
}
}
