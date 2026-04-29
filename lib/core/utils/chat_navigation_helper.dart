import 'package:get/get.dart';
import 'package:LinkLian/core/services/local_storage.dart';
import 'package:LinkLian/features/chat/presentation/controllers/chat.controller.dart';
import 'package:LinkLian/features/chat/presentation/pages/chat.message.page.dart';
import 'package:LinkLian/features/chat/data/models/chat.model.dart';
import 'package:LinkLian/features/shared/models/profile_model.dart';

Future<void> openChatWithUser(ProfileModel profile) async {
  final chatController = ChatController();

  final currentUserId = await LocalStorage.getLastLoginUserId();

  if (currentUserId == null) {
    return;
  }

  final chats = await chatController.getChat();

  ChatModel? existingChat;

  for (final chat in chats) {
    if (chat.userSysId == profile.userSysId) {
      existingChat = chat;
      break;
    }
  }

  if (existingChat != null) {
    Get.to(() => ChatMessagePage(chat: existingChat!));
    return;
  }

  final newChat = await chatController.createChat(
    isAiChat: false,
    senderId: currentUserId,
    receiverId: profile.userSysId,
  );

  final chat = ChatModel(
    chatId: newChat.chatId,
    senderId: newChat.senderId,
    receiverId: newChat.receiverId,
    userSysId: profile.userSysId,
    firstName: profile.firstName,
    lastName: profile.lastName,
    profileImage: profile.profilePic,
  );

  Get.to(() => ChatMessagePage(chat: chat));
}