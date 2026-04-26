import 'package:json_annotation/json_annotation.dart';

part 'chat.model.g.dart';

@JsonSerializable()
class ChatModel {
  @JsonKey(name: 'chat_id', fromJson: _intFromJsonNullable)
  final int? chatId;

  @JsonKey(name: 'user_sys_id', fromJson: _intFromJsonNullable)
  final int? userSysId;

  @JsonKey(name: 'message_id', fromJson: _intFromJsonNullable)
  final int? messageId;

  final String? content;

  @JsonKey(name: 'is_ai_chat')
  final bool? isAiChat;

  @JsonKey(name: 'sender_id', fromJson: _intFromJsonNullable)
  final int? senderId;

  @JsonKey(name: 'last_messages')
  final String? lastMessage;

  @JsonKey(name: 'last_sent', fromJson: _dateTimeFromJson)
  final DateTime? lastSent;

  @JsonKey(name: 'receiver_id', fromJson: _intFromJsonNullable)
  final int? receiverId;

  @JsonKey(name: 'reply_id', fromJson: _intFromJsonNullable)
  final int? replyId;

  final List<dynamic>? file;

  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson)
  final DateTime? createdAt;

  @JsonKey(name: 'updated_at', fromJson: _dateTimeFromJson)
  final DateTime? updatedAt;

  @JsonKey(name: 'flag_valid')
  final bool? flagValid;

  final int? offset;
  final int? limit;

  @JsonKey(name: 'sort_by')
  final String? sortBy;

  @JsonKey(name: 'sort_order')
  final String? sortOrder;

  @JsonKey(name: 'first_name')
  final String? firstName;

  @JsonKey(name: 'last_name')
  final String? lastName;

  @JsonKey(name: 'profile_pic')
  final String? profileImage;

  @JsonKey(name: 'unread_count', fromJson: _intFromJsonNullable)
  final int? unreadCount;

  @JsonKey(name: 'is_read', fromJson: _boolFromJson)
  final bool? isRead;
  static bool? _boolFromJson(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value != 0;
    return null;
  }

  const ChatModel({
    this.chatId,
    this.userSysId,
    this.messageId,
    this.content,
    this.isAiChat,
    this.senderId,
    this.lastMessage,
    this.lastSent,
    this.receiverId,
    this.replyId,
    this.file,
    this.createdAt,
    this.updatedAt,
    this.flagValid,
    this.offset,
    this.limit,
    this.sortBy,
    this.sortOrder,
    this.firstName,
    this.lastName,
    this.profileImage,
    this.unreadCount,
    this.isRead,
  });

  // static int _intFromJson(dynamic value) {
  //   if (value == null) throw Exception('Required int value is null');
  //   if (value is int) return value;
  //   if (value is String) return int.parse(value);
  //   throw Exception('Invalid int value: $value');
  // }

  static int? _intFromJsonNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _dateTimeFromJson(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) =>
      _$ChatModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatModelToJson(this);

  @override
  String toString() {
    return 'ChatModel(chatId: $chatId, userSysId: $userSysId, lastMessage: $lastMessage, profileImage: $profileImage)';
  }
}
