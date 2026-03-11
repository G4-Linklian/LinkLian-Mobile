import 'package:json_annotation/json_annotation.dart';
import '../models/section_educator_model.dart';
import '../../classes/data/models/class_schedule_model.dart';


part 'class_info_model.g.dart';

int _intFromJson(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
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

    @JsonKey(name: 'schedules', defaultValue: [])
  final List<ClassScheduleModel> schedules;

  @JsonKey(name: 'members', defaultValue: [])
  final List<Map<String, dynamic>> members;

  @JsonKey(name: 'educators', defaultValue: [])
  final List<SectionEducatorModel> educators;


  final int studentCount;

  const ClassInfoModel({
    required this.sectionId,
    this.sectionName,
    this.subjectName,
    this.semester,
    this.studentCount = 0,
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