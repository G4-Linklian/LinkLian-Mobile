import 'dart:convert';

class NotiDataModel {
  final String title;
  final String body;
  final String actorName;
  final String refId;
  final String refType;
  final String? sectionId;
  final String? communityId;

  const NotiDataModel({
    required this.title,
    required this.body,
    required this.actorName,
    required this.refId,
    required this.refType,
    this.sectionId,
    this.communityId,
  });

  factory NotiDataModel.fromJson(Map<String, dynamic> json) {
    return NotiDataModel(
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      actorName: json['actor_name']?.toString() ?? '',
      refId: json['ref_id']?.toString() ?? '',
      refType: json['ref_type']?.toString() ?? '',
      sectionId: json['section_id']?.toString(),
      communityId: json['community_id']?.toString(),
    );
  }
}

class NotificationModel {
  final int notificationId;
  final String type;
  final String feature;
  final int actorId;
  final NotiDataModel notiData;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.notificationId,
    required this.type,
    required this.feature,
    required this.actorId,
    required this.notiData,
    required this.createdAt,
    required this.isRead,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // noti_data อาจมาเป็น Map หรือ String (JSON string)
    final rawNotiData = json['noti_data'];
    Map<String, dynamic> notiDataMap;
    if (rawNotiData is Map<String, dynamic>) {
      notiDataMap = rawNotiData;
    } else if (rawNotiData is String) {
      notiDataMap = Map<String, dynamic>.from(jsonDecode(rawNotiData));
    } else {
      notiDataMap = {};
    }

    return NotificationModel(
      notificationId: int.tryParse(json['notification_id'].toString()) ?? 0,
      type: json['type']?.toString() ?? '',
      feature: json['feature']?.toString() ?? '',
      actorId: int.tryParse(json['actor_id']?.toString() ?? '0') ?? 0,
      notiData: NotiDataModel.fromJson(notiDataMap),
      createdAt: DateTime.tryParse(json['noti_created_at']?.toString() ?? '') ?? DateTime.now(),
      isRead: json['is_read'] == true,
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      notificationId: notificationId,
      type: type,
      feature: feature,
      actorId: actorId,
      notiData: notiData,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
