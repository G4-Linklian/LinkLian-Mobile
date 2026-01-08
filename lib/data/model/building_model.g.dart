// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'building_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuildingModel _$BuildingModelFromJson(Map<String, dynamic> json) =>
    BuildingModel(
      buildingId: BuildingModel._intFromJson(json['building_id']),
      buildingName: json['building_name'] as String,
      buildingNo: json['building_no'] as String?,
      roomFormat: json['room_format'] as String?,
    );

Map<String, dynamic> _$BuildingModelToJson(BuildingModel instance) =>
    <String, dynamic>{
      'building_id': instance.buildingId,
      'building_name': instance.buildingName,
      'building_no': instance.buildingNo,
      'room_format': instance.roomFormat,
    };
