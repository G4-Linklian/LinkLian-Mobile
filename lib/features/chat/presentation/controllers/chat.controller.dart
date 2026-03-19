import 'package:LinkLian/features/chat/data/repository/chat.repository.dart';
import 'package:LinkLian/core/services/local_storage.dart';
import 'package:LinkLian/features/chat/data/models/chat.model.dart';
// import 'package:LinkLian/core/utils/logger.dart';

class ChatController {
  final ChatRepository _chatRepository = ChatRepository();

  /// GET CHAT
  Future<List<ChatModel>> getChat() async {
    final userSysId = await LocalStorage.getLastLoginUserId();
    return await _chatRepository.getChat(
      userSysId: userSysId,
      sortBy: 'last_sent',
      sortOrder: 'desc',
    );
  }

  /// CREATE CHAT
  Future<ChatModel> createChat({
    required bool isAiChat,
    required int senderId,
    required int receiverId,
  }) async {
    return await _chatRepository.createChat(
      isAiChat: isAiChat,
      senderId: senderId,
      receiverId: receiverId,
    );
  }

  /// UPDATE CHAT
  Future<ChatModel> updateChat({
    required int chatId,
    bool? isAiChat,
    bool? flagValid,
  }) async {
    return await _chatRepository.updateChat(
      chatId: chatId,
      isAiChat: isAiChat,
      flagValid: flagValid,
    );
  }

  /// SEARCH USER FOR CREATE CHAT
  Future<List<ChatModel>> searchUsers(String keyword) async {
    final userSysId = await LocalStorage.getLastLoginUserId();

    return await _chatRepository.searchUsers(
      userSysId: userSysId!,
      keyword: keyword,
    );
  }
}
