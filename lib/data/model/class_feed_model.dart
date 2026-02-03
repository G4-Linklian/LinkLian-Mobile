import 'package:json_annotation/json_annotation.dart';
import 'class_schedule_model.dart';

part 'class_feed_model.g.dart';

@JsonSerializable()
class ClassFeedModel {
  @JsonKey(
    name: 'section_id',
    fromJson: _intFromJson,
  )
  final int sectionId;

  @JsonKey(name: 'section_name')
  final String sectionName;

  @JsonKey(name: 'subject_code')
  final String subjectCode;

  @JsonKey(name: 'subject_name_th')
  final String subjectNameTh;

  @JsonKey(name: 'subject_name_en')
  final String subjectNameEn;

  @JsonKey(name: 'learning_area_name')
  final String? learningAreaName;

  final String semester;

  @JsonKey(name: 'schedules')
  final List<ClassScheduleModel> schedules;

  final String? position;

  @JsonKey(name: 'edu_type')
  final String? eduType;

  @JsonKey(name: 'level_num')
  final int? levelNum;

  @JsonKey(name: 'level_name')
  final String? levelName;

  @JsonKey(name: 'class_name')
  final String? className;

  @JsonKey(name: 'program_type')
  final String? programType;

  @JsonKey(name: 'study_plan_name')
  final String? studyPlanName;

  @JsonKey(name: 'display_class_name')
  final String? displayClassName;

  const ClassFeedModel({
    required this.sectionId,
    required this.sectionName,
    required this.subjectCode,
    required this.subjectNameTh,
    required this.subjectNameEn,
    this.learningAreaName,
    required this.semester,
    required this.schedules,
    this.displayClassName,
    this.position,
    this.eduType,
    this.levelNum,
    this.levelName,
    this.className,
    this.programType,
    this.studyPlanName,
  });

  String get effectiveClassName => displayClassName ?? sectionName;

  static int _intFromJson(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.parse(value);
    throw Exception('Invalid int value: $value');
  }

  factory ClassFeedModel.fromJson(Map<String, dynamic> json) =>
      _$ClassFeedModelFromJson(json);

  Map<String, dynamic> toJson() => _$ClassFeedModelToJson(this);

  @override
  String toString() {
    return 'ClassFeedModel(sectionId: $sectionId, displayClassName: $displayClassName)';
  }
}