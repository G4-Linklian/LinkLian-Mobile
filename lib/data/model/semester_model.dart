import 'package:json_annotation/json_annotation.dart';

part 'semester_model.g.dart';

@JsonSerializable()
class SemesterModel {
  @JsonKey(
    name: 'semester_id',
    fromJson: _intFromJson,
  )
  final int semesterId;

  final String semester;
  final String status;

  @JsonKey(name: 'flag_valid')
  final bool flagValid;

  @JsonKey(name: 'start_date')
  final DateTime startDate;

  @JsonKey(name: 'end_date')
  final DateTime endDate;

  const SemesterModel({
    required this.semesterId,
    required this.semester,
    required this.status,
    required this.flagValid,
    required this.startDate,
    required this.endDate,
  });

  static int _intFromJson(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.parse(value);
    throw Exception('Invalid semester_id type: $value');
  }

  factory SemesterModel.fromJson(Map<String, dynamic> json) =>
      _$SemesterModelFromJson(json);

  Map<String, dynamic> toJson() => _$SemesterModelToJson(this);

  @override
  String toString() {
    return 'SemesterModel(id: $semesterId, semester: $semester)';
  }
}