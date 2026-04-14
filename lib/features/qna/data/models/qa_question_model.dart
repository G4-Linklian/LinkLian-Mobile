import 'package:json_annotation/json_annotation.dart';
import 'qa_asker_model.dart';

part 'qa_question_model.g.dart';

int _intFromJson(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

bool _boolFromJson(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
  return false;
}

DateTime _dateTimeFromJson(dynamic value) {
  if (value is DateTime) return value;
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}

@JsonSerializable()
class QaQuestion {

  @JsonKey(name: 'qa_question_id')
  final dynamic qaQuestionId;

  @JsonKey(name: 'qa_live_id', fromJson: _intFromJson)
  final int qaLiveId;

  final String question;

  @JsonKey(name: 'asker_id', fromJson: _intFromJson)
  final int? askerId;

  final QaAsker? asker;

  @JsonKey(name: 'upvote_count', fromJson: _intFromJson)
  final int upvoteCount;

  @JsonKey(name: 'is_upvoted', fromJson: _boolFromJson)
  final bool isUpvoted;

  @JsonKey(name: 'is_anonymous', fromJson: _boolFromJson)
  final bool isAnonymous;

  @JsonKey(name: 'slide_number', fromJson: _intFromJson)
  final int slideNumber;

  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson)
  final DateTime createdAt;

  @JsonKey(name: 'post_id', fromJson: _intFromJson)
  final int? postId;

  @JsonKey(name: 'attachment_id', fromJson: _intFromJson)
  final int? attachmentId;

  final String? status;

  @JsonKey(name: 'is_local_pending', fromJson: _boolFromJson)
  final bool isLocalPending;

  QaQuestion({
    required this.qaQuestionId,
    required this.qaLiveId,
    required this.question,
    this.askerId,
    this.asker,
    this.upvoteCount = 0,
    this.isUpvoted = false,
    this.isAnonymous = false,
    this.slideNumber = 0,
    DateTime? createdAt,
    this.postId,
    this.attachmentId,
    this.status,
    this.isLocalPending = false,
  }) : createdAt = createdAt ?? DateTime.now();

  factory QaQuestion.fromJson(Map<String, dynamic> json) =>
      _$QaQuestionFromJson(json);

  Map<String, dynamic> toJson() => _$QaQuestionToJson(this);

  QaQuestion copyWith({
    dynamic qaQuestionId,
    int? qaLiveId,
    String? question,
    int? askerId,
    QaAsker? asker,
    int? upvoteCount,
    bool? isUpvoted,
    bool? isAnonymous,
    int? slideNumber,
    DateTime? createdAt,
    int? postId,
    int? attachmentId,
    String? status,
    bool? isLocalPending,
  }) {
    return QaQuestion(
      qaQuestionId: qaQuestionId ?? this.qaQuestionId,
      qaLiveId: qaLiveId ?? this.qaLiveId,
      question: question ?? this.question,
      askerId: askerId ?? this.askerId,
      asker: asker ?? this.asker,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      isUpvoted: isUpvoted ?? this.isUpvoted,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      slideNumber: slideNumber ?? this.slideNumber,
      createdAt: createdAt ?? this.createdAt,
      postId: postId ?? this.postId,
      attachmentId: attachmentId ?? this.attachmentId,
      status: status ?? this.status,
      isLocalPending: isLocalPending ?? this.isLocalPending,
    );
  }

  String get askerName => asker?.fullName ?? 'ผู้ใช้ทั่วไป';

  dynamic operator [](String key) {
    switch (key) {
      case 'qa_question_id':
        return qaQuestionId;
      case 'question':
        return question;
      case 'asker_id':
        return askerId;
      case 'asker':
        return asker?.toJson();
      case 'upvote_count':
        return upvoteCount;
      case 'is_upvoted':
        return isUpvoted;
      case 'is_anonymous':
        return isAnonymous;
      case 'slide_number':
        return slideNumber;
      case 'created_at':
        return createdAt.toIso8601String();
      case 'post_id':
        return postId;
      case 'attachment_id':
        return attachmentId;
      case 'status':
        return status;
      case 'is_local_pending':
        return isLocalPending;
      case 'qa_live_id':
        return qaLiveId;
      default:
        return null;
    }
  }

  @override
  String toString() =>
      'QaQuestion(qaQuestionId: $qaQuestionId, question: $question, askerName: $askerName)';
}
