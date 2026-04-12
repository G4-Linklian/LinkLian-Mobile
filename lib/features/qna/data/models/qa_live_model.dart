import 'package:json_annotation/json_annotation.dart';

part 'qa_live_model.g.dart';

int _intFromJson(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime _dateTimeFromJson(dynamic value) {
  if (value is DateTime) return value;
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value) ?? DateTime(1970, 1, 1);
  }
  return DateTime(1970, 1, 1);
}

@JsonSerializable()
class QaLive {
  @JsonKey(name: 'qa_live_id', fromJson: _intFromJson)
  final int qaLiveId;

  @JsonKey(name: 'live_title')
  final String? liveTitle;

  @JsonKey(name: 'section_id', fromJson: _intFromJson)
  final int sectionId;

  @JsonKey(name: 'live_by', fromJson: _intFromJson)
  final int? liveBy;

  @JsonKey(name: 'post_id', fromJson: _intFromJson)
  final int? postId;

  @JsonKey(name: 'started_at', fromJson: _dateTimeFromJson)
  final DateTime createdAt;

  @JsonKey(name: 'ended_at', fromJson: _dateTimeFromJson)
  final DateTime? updatedAt;

  @JsonKey(name: 'current_slide')
  final Map<String, dynamic>? currentSlide;

  QaLive({
    required this.qaLiveId,
    this.liveTitle,
    required this.sectionId,
    this.liveBy,
    this.postId,
    DateTime? createdAt,
    this.updatedAt,
    this.currentSlide,
  }) : createdAt = createdAt ?? DateTime.now();

  factory QaLive.fromJson(Map<String, dynamic> json) =>
      _$QaLiveFromJson(json);

  Map<String, dynamic> toJson() => _$QaLiveToJson(this);

  QaLive copyWith({
    int? qaLiveId,
    String? liveTitle,
    int? sectionId,
    int? liveBy,
    int? postId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? currentSlide,
  }) {
    return QaLive(
      qaLiveId: qaLiveId ?? this.qaLiveId,
      liveTitle: liveTitle ?? this.liveTitle,
      sectionId: sectionId ?? this.sectionId,
      liveBy: liveBy ?? this.liveBy,
      postId: postId ?? this.postId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentSlide: currentSlide ?? this.currentSlide,
    );
  }

  @override
  String toString() =>
      'QaLive(qaLiveId: $qaLiveId, liveTitle: $liveTitle, sectionId: $sectionId)';
}
