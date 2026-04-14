import 'package:json_annotation/json_annotation.dart';

part 'qa_asker_model.g.dart';

int? _intFromJson(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
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

@JsonSerializable()
class QaAsker {
  @JsonKey(name: 'user_id', fromJson: _intFromJson)
  final int? userId;

  @JsonKey(name: 'first_name')
  final String? firstName;

  @JsonKey(name: 'last_name')
  final String? lastName;

  @JsonKey(name: 'profile_pic')
  final String? profilePic;

  @JsonKey(name: 'is_anonymous', fromJson: _boolFromJson)
  final bool isAnonymous;

  QaAsker({
    this.userId,
    this.firstName,
    this.lastName,
    this.profilePic,
    this.isAnonymous = false,
  });

  factory QaAsker.fromJson(Map<String, dynamic> json) =>
      _$QaAskerFromJson(json);

  Map<String, dynamic> toJson() => _$QaAskerToJson(this);

  String get fullName {
    final first = firstName?.trim() ?? '';
    final last = lastName?.trim() ?? '';
    final combined = [first, last].where((e) => e.isNotEmpty).join(' ').trim();
    return combined.isNotEmpty
        ? combined
        : (isAnonymous ? 'ผู้ใช้ไม่ระบุตัวตน' : 'ผู้ใช้ทั่วไป');
  }

  QaAsker copyWith({
    int? userId,
    String? firstName,
    String? lastName,
    String? profilePic,
    bool? isAnonymous,
  }) {
    return QaAsker(
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profilePic: profilePic ?? this.profilePic,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }

  @override
  String toString() =>
      'QaAsker(userId: $userId, fullName: $fullName, isAnonymous: $isAnonymous)';
}
