import 'package:LinkLian/core/utils/logger.dart';

import '../../core/services/api_client.dart';
import '../model/chat.model.dart';

class ChatRepository {
  final ApiClient _apiClient = ApiClient();

  /// GET CHAT (dynamic filter)
  Future<List<ChatModel>> getChat({
    int? chatId,
    int? userSysId,
    bool? isAiChat,
    bool? flagValid,
    String? sortBy,
    String? sortOrder,
    int? limit,
    int? offset,
  }) async {
    final Map<String, dynamic> body = {};

    if (chatId != null) body['chat_id'] = chatId;
    if (userSysId != null) body['user_sys_id'] = userSysId;
    if (isAiChat != null) body['is_ai_chat'] = isAiChat;
    if (flagValid != null) body['flag_valid'] = flagValid;
    if (sortBy != null) body['sort_by'] = sortBy;
    if (sortOrder != null) body['sort_order'] = sortOrder;
    if (limit != null) body['limit'] = limit;
    if (offset != null) body['offset'] = offset;

    final response = await _apiClient.post<Map<String, dynamic>>(
      '/chat.get',
      data: body,
    );

    if (response.statusCode == 200 && response.data != null) {
      final list = response.data!['data'] as List;
      appLog.info('Response data: ${response.data!['data']}');

      appLog.info('Fetched chats count: ${list.length}');

      try {
        final chats = list.map((chatJson) {
          appLog.info('Parsing chatJson: $chatJson');
          return ChatModel.fromJson(Map<String, dynamic>.from(chatJson));
        }).toList();

        appLog.info('Parsed chats count: ${chats.length}');
        return chats;
      } catch (e, stack) {
        appLog.error('❌ Error parsing chats');
        appLog.error('$e');
        appLog.error('$stack');
        rethrow;
      }
    }

    throw Exception('Failed to fetch chats');
  }

  /// CREATE CHAT
  Future<ChatModel> createChat({
    required bool isAiChat,
    required int senderId,
    required int receiverId,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/chat.create',
      data: {
        'is_ai_chat': isAiChat,
        'sender_id': senderId,
        'receiver_id': receiverId,
      },
    );

    if (response.statusCode == 201 && response.data != null) {
      return ChatModel.fromJson(
        Map<String, dynamic>.from(response.data!['data']),
      );
    }

    throw Exception('Failed to create chat');
  }

  /// UPDATE CHAT
  Future<ChatModel> updateChat({
    required int chatId,
    bool? isAiChat,
    bool? flagValid,
  }) async {
    final Map<String, dynamic> body = {'chat_id': chatId};

    if (isAiChat != null) body['is_ai_chat'] = isAiChat;
    if (flagValid != null) body['flag_valid'] = flagValid;

    final response = await _apiClient.post<Map<String, dynamic>>(
      '/chat.update',
      data: body,
    );

    if (response.statusCode == 200 && response.data != null) {
      return ChatModel.fromJson(
        Map<String, dynamic>.from(response.data!['data']),
      );
    }

    throw Exception('Failed to update chat');
  }

  /// DELETE CHAT
  Future<void> deleteChat({required int chatId}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/chat.delete',
      data: {'chat_id': chatId},
    );

    if (response.statusCode == 200) {
      appLog.info('Chat deleted successfully');
      return;
    }

    throw Exception('Failed to delete chat');
  }

  /// GET MESSAGE
  Future<List<ChatModel>> getMessage({
    int? messageId,
    int? chatId,
    int? senderId,
    String? content,
    int? replyId,
    bool? flagValid,
    String? sortBy,
    String? sortOrder,
    int? limit,
    int? offset,
  }) async {
    final Map<String, dynamic> body = {};

    if (messageId != null) body['message_id'] = messageId;
    if (chatId != null) body['chat_id'] = chatId;
    if (senderId != null) body['sender_id'] = senderId;
    if (content != null) body['content'] = content;
    if (replyId != null) body['reply_id'] = replyId;
    if (flagValid != null) body['flag_valid'] = flagValid;
    if (sortBy != null) body['sort_by'] = sortBy;
    if (sortOrder != null) body['sort_order'] = sortOrder;
    if (limit != null) body['limit'] = limit;
    if (offset != null) body['offset'] = offset;

    final response = await _apiClient.post<Map<String, dynamic>>(
      '/message.get',
      data: body,
    );

    if (response.statusCode == 200 && response.data != null) {
      final list = response.data!['data'] as List;
      return list.map((e) => ChatModel.fromJson(Map<String, dynamic>.from(e))).toList();
    }

    throw Exception('Failed to fetch messages');
  }

  /// CREATE MESSAGE
  Future<ChatModel> createMessage({
    required int chatId,
    required int senderId,
    required String content,
    int? replyId,
    List<dynamic>? file,
  }) async {
    final Map<String, dynamic> body = {
      'chat_id': chatId,
      'sender_id': senderId,
      'content': content,
    };

    if (replyId != null) body['reply_id'] = replyId;
    if (file != null) body['file'] = file;

    final response = await _apiClient.post<Map<String, dynamic>>(
      '/message.create',
      data: body,
    );

    if (response.statusCode == 201 && response.data != null) {
      final data = response.data!['data'];
      
      // Handle if data is a List, take the first item
      if (data is List && data.isNotEmpty) {
        return ChatModel.fromJson(Map<String, dynamic>.from(data.first));
      }
      // Handle if data is already a Map
      else if (data is Map) {
        return ChatModel.fromJson(Map<String, dynamic>.from(data));
      }
      
      throw Exception('Invalid response data format');
    }

    throw Exception('Failed to create message');
  }
}
