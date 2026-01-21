import 'package:json_annotation/json_annotation.dart';

part 'education_model.g.dart';

@JsonSerializable()
class EducationModel {
  final String type;

  /// high school
  final String? level;        
  final String? classroom; 
  
  @JsonKey(name: 'study_plan')
  final String? studyPlan;

  /// university
  final String? faculty;      
  final String? program;      
  final int? year;            

  final String display;       

  EducationModel({
    required this.type,
    this.level,
    this.classroom,
    this.studyPlan,
    this.faculty,
    this.program,
    this.year,
    required this.display,
  });

  factory EducationModel.fromJson(Map<String, dynamic> json) =>
      _$EducationModelFromJson(json);

  Map<String, dynamic> toJson() => _$EducationModelToJson(this);
}
