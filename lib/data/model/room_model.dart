import 'package:json_annotation/json_annotation.dart';

part 'room_model.g.dart';

@JsonSerializable()
class RoomModel {
  @JsonKey(name: 'room_location_id', fromJson: _intFromJson)
  final int roomLocationId;

  @JsonKey(name: 'room_number')
  final String? roomNumber;

  final int? floor;

  @JsonKey(name: 'room_remark')
  final String? roomRemark;

  const RoomModel({
    required this.roomLocationId,
    this.roomNumber,
    this.floor,
    this.roomRemark,
  });

  static int _intFromJson(dynamic v) =>
      v is int ? v : int.parse(v.toString());

  factory RoomModel.fromJson(Map<String, dynamic> json) =>
      _$RoomModelFromJson(json);

  Map<String, dynamic> toJson() => _$RoomModelToJson(this);
}