import 'package:json_annotation/json_annotation.dart';
import '../models/section_educator_model.dart';
import '../../classes/data/models/class_schedule_model.dart';

part 'class_info_model.g.dart';

int _intFromJson(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

String? _stringFromJson(dynamic value) {
  if (value == null) return null;
  final result = value.toString().trim();
  return result.isEmpty ? null : result;
}

List<ClassScheduleModel> _schedulesFromJson(dynamic value) {
  if (value is! List) return const <ClassScheduleModel>[];

  return value.whereType<Map>().map((item) {
    return ClassScheduleModel.fromJson(Map<String, dynamic>.from(item));
  }).toList();
}

List<Map<String, dynamic>> _membersFromJson(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];

  return value.whereType<Map>().map((item) {
    return Map<String, dynamic>.from(item);
  }).toList();
}

List<SectionEducatorModel> _educatorsFromJson(dynamic value) {
  if (value is! List) return const <SectionEducatorModel>[];

  return value.whereType<Map>().map((item) {
    return SectionEducatorModel.fromJson(Map<String, dynamic>.from(item));
  }).toList();
}

@JsonSerializable()
class ClassInfoModel {
  @JsonKey(name: 'section_id', fromJson: _intFromJson)
  final int sectionId;

  @JsonKey(name: 'section_name')
  final String? sectionName;

  @JsonKey(name: 'subject_name')
  final String? subjectName;

  @JsonKey(name: 'semester')
  final String? semester;

  @JsonKey(name: 'student_count', fromJson: _intFromJson, defaultValue: 0)
  final int studentCount;

  @JsonKey(name: 'room_location', fromJson: _stringFromJson)
  final String? roomLocation;

  @JsonKey(name: 'schedules', fromJson: _schedulesFromJson)
  final List<ClassScheduleModel> schedules;

  @JsonKey(name: 'members', fromJson: _membersFromJson)
  final List<Map<String, dynamic>> members;

  @JsonKey(name: 'educators', fromJson: _educatorsFromJson)
  final List<SectionEducatorModel> educators;

  const ClassInfoModel({
    required this.sectionId,
    this.sectionName,
    this.subjectName,
    this.semester,
    this.studentCount = 0,
    this.roomLocation,
    this.schedules = const [],
    this.members = const [],
    this.educators = const [],
  });

  factory ClassInfoModel.fromJson(Map<String, dynamic> json) =>
      _$ClassInfoModelFromJson(json);

  Map<String, dynamic> toJson() => _$ClassInfoModelToJson(this);

  @override
  String toString() {
    return 'ClassInfoModel(sectionId: $sectionId, sectionName: $sectionName)';
  }
}
