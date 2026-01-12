// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoomModel _$RoomModelFromJson(Map<String, dynamic> json) => RoomModel(
  roomLocationId: RoomModel._intFromJson(json['room_location_id']),
  roomNumber: json['room_number'] as String?,
  floor: json['floor'] as String?,
  roomRemark: json['room_remark'] as String?,
);

Map<String, dynamic> _$RoomModelToJson(RoomModel instance) => <String, dynamic>{
  'room_location_id': instance.roomLocationId,
  'room_number': instance.roomNumber,
  'floor': instance.floor,
  'room_remark': instance.roomRemark,
};
