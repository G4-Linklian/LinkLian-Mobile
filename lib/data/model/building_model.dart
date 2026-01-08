import 'package:json_annotation/json_annotation.dart';

part 'building_model.g.dart';

@JsonSerializable()
class BuildingModel {
  @JsonKey(name: 'building_id', fromJson: _intFromJson)
  final int buildingId;

  @JsonKey(name: 'building_name')
  final String buildingName;

  @JsonKey(name: 'building_no')
  final String? buildingNo;

  @JsonKey(name: 'room_format')
  final String? roomFormat;

  const BuildingModel({
    required this.buildingId,
    required this.buildingName,
    this.buildingNo,
    this.roomFormat,
  });

  static int _intFromJson(dynamic v) =>
      v is int ? v : int.parse(v.toString());

  factory BuildingModel.fromJson(Map<String, dynamic> json) =>
      _$BuildingModelFromJson(json);

  Map<String, dynamic> toJson() => _$BuildingModelToJson(this);
}