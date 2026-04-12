/// Shared model สำหรับ notification ที่มาจากทั้ง Socket และ FCM
/// ทั้งสองช่องทางถูก normalize ให้เป็น object นี้ก่อนส่งต่อ
class NotificationPayload {
  final String notificationId;
  final String receiveUserId;
  final String actorId;
  final String actorName;
  final String title;
  final String body;
  final String refId;
  final String refType;
  final String feature;
  /// section ที่โพสต์สังกัด — มีเฉพาะ ref_type = 'feed-post'
  final String? sectionId;
  /// community ที่โพสต์สังกัด — มีเฉพาะ ref_type = 'community-post'
  final String? communityId;

  const NotificationPayload({
    required this.notificationId,
    required this.receiveUserId,
    required this.actorId,
    required this.actorName,
    required this.title,
    required this.body,
    required this.refId,
    required this.refType,
    required this.feature,
    this.sectionId,
    this.communityId,
  });

  /// Parse จาก Socket message (payload field ของ NOTIFICATION event)
  factory NotificationPayload.fromSocket(Map<String, dynamic> payload) {
    return NotificationPayload(
      notificationId: payload['notification_id']?.toString() ?? '',
      receiveUserId: payload['receive_user_id']?.toString() ?? '',
      actorId: payload['actor_id']?.toString() ?? '',
      actorName: payload['actor_name']?.toString() ?? '',
      title: payload['title']?.toString() ?? '',
      body: payload['body']?.toString() ?? '',
      refId: payload['ref_id']?.toString() ?? '',
      refType: payload['ref_type']?.toString() ?? '',
      feature: payload['feature']?.toString() ?? 'default',
      sectionId: payload['section_id']?.toString(),
      communityId: payload['community_id']?.toString(),
    );
  }

  /// Parse จาก FCM data message
  factory NotificationPayload.fromFCM(Map<String, dynamic> data) {
    return NotificationPayload(
      notificationId: data['notification_id']?.toString() ?? '',
      receiveUserId: data['receive_user_id']?.toString() ?? '',
      actorId: data['actor_id']?.toString() ?? '',
      actorName: data['actor_name']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      body: data['body']?.toString() ?? '',
      refId: data['ref_id']?.toString() ?? '',
      refType: data['ref_type']?.toString() ?? '',
      feature: data['feature']?.toString() ?? 'default',
      sectionId: data['section_id']?.toString(),
      communityId: data['community_id']?.toString(),
    );
  }
}
