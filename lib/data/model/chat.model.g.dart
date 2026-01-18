// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatModel _$ChatModelFromJson(Map<String, dynamic> json) => ChatModel(
  chatId: ChatModel._intFromJsonNullable(json['chat_id']),
  userSysId: ChatModel._intFromJsonNullable(json['user_sys_id']),
  messageId: ChatModel._intFromJsonNullable(json['message_id']),
  content: json['content'] as String?,
  isAiChat: json['is_ai_chat'] as bool?,
  senderId: ChatModel._intFromJsonNullable(json['sender_id']),
  lastMessage: json['last_messages'] as String?,
  lastSent: ChatModel._dateTimeFromJson(json['last_sent']),
  receiverId: ChatModel._intFromJsonNullable(json['receiver_id']),
  replyId: ChatModel._intFromJsonNullable(json['reply_id']),
  file: json['file'] as List<dynamic>?,
  createdAt: ChatModel._dateTimeFromJson(json['created_at']),
  updatedAt: ChatModel._dateTimeFromJson(json['updated_at']),
  flagValid: json['flag_valid'] as bool?,
  offset: (json['offset'] as num?)?.toInt(),
  limit: (json['limit'] as num?)?.toInt(),
  sortBy: json['sort_by'] as String?,
  sortOrder: json['sort_order'] as String?,
  firstName: json['first_name'] as String?,
  lastName: json['last_name'] as String?,
  profileImage: json['profile_pic'] as String?,
);

Map<String, dynamic> _$ChatModelToJson(ChatModel instance) => <String, dynamic>{
  'chat_id': instance.chatId,
  'user_sys_id': instance.userSysId,
  'message_id': instance.messageId,
  'content': instance.content,
  'is_ai_chat': instance.isAiChat,
  'sender_id': instance.senderId,
  'last_messages': instance.lastMessage,
  'last_sent': instance.lastSent?.toIso8601String(),
  'receiver_id': instance.receiverId,
  'reply_id': instance.replyId,
  'file': instance.file,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'flag_valid': instance.flagValid,
  'offset': instance.offset,
  'limit': instance.limit,
  'sort_by': instance.sortBy,
  'sort_order': instance.sortOrder,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'profile_pic': instance.profileImage,
};
