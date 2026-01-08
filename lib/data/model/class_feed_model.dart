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
  final String learningAreaName;

  final String semester;

  @JsonKey(name: 'schedules')
final List<ClassScheduleModel> schedules;

  /// สำหรับครูเท่านั้น (nullable)
  final String? position;

  const ClassFeedModel({
    required this.sectionId,
    required this.sectionName,
    required this.subjectCode,
    required this.subjectNameTh,
    required this.subjectNameEn,
    required this.learningAreaName,
    required this.semester,
    required this.schedules,
    this.position,
  });

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
    return 'ClassFeedModel(sectionId: $sectionId, sectionName: $sectionName)';
  }
}