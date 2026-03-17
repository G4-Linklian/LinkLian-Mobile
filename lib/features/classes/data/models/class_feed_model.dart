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

  @JsonKey(name: 'student_count', fromJson: _intFromJson, defaultValue: 0)
  final int studentCount;

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
    this.studentCount = 0,
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
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _stringFromJson(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  static int? _nullableIntFromJson(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static List<ClassScheduleModel> _schedulesFromJson(dynamic value) {
    if (value is! List) return const <ClassScheduleModel>[];
    return value.whereType<Map>().map((e) {
      try {
        return ClassScheduleModel.fromJson(Map<String, dynamic>.from(e));
      } catch (_) {
        return const ClassScheduleModel(
          dayOfWeek: 0,
          startTime: '',
          endTime: '',
          room: null,
          building: null,
        );
      }
    }).where((e) => e.dayOfWeek != 0 || e.startTime.isNotEmpty || e.endTime.isNotEmpty).toList();
  }

  factory ClassFeedModel.fromJson(Map<String, dynamic> json) {
    return ClassFeedModel(
      sectionId: _intFromJson(json['section_id']),
      sectionName: _stringFromJson(json['section_name']),
      subjectCode: _stringFromJson(json['subject_code']),
      subjectNameTh: _stringFromJson(json['subject_name_th']),
      subjectNameEn: _stringFromJson(json['subject_name_en']),
      learningAreaName: json['learning_area_name']?.toString(),
      semester: _stringFromJson(json['semester']),
      studentCount: _intFromJson(json['student_count']),
      schedules: _schedulesFromJson(json['schedules']),
      displayClassName: json['display_class_name']?.toString(),
      position: json['position']?.toString(),
      eduType: json['edu_type']?.toString(),
      levelNum: _nullableIntFromJson(json['level_num']),
      levelName: json['level_name']?.toString(),
      className: json['class_name']?.toString(),
      programType: json['program_type']?.toString(),
      studyPlanName: json['study_plan_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => _$ClassFeedModelToJson(this);

  @override
  String toString() {
    return 'ClassFeedModel(sectionId: $sectionId, displayClassName: $displayClassName)';
  }
}
