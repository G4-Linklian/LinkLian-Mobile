import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

part 'assignment_model.g.dart';

int _intFromJson(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime? _dateTimeFromJson(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

List<Map<String, dynamic>>? _educatorsFromJson(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    return value.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  return null;
}

@JsonSerializable()
class AssignmentModel {
  @JsonKey(name: 'assignment_id', fromJson: _intFromJson)
  final int assignmentId;

  @JsonKey(name: 'post_id', fromJson: _intFromJson)
  final int postId;

  final String title;

  @JsonKey(name: 'subject_name_th')
  final String subjectNameTh;

  @JsonKey(name: 'subject_name_en')
  final String subjectNameEn;

  @JsonKey(name: 'assignment_type')
  final String assignmentType;

  @JsonKey(name: 'due_date', fromJson: _dateTimeFromJson)
  final DateTime? dueDate;

  @JsonKey(name: 'total_students', fromJson: _intFromJson)
  final int totalStudents;

  @JsonKey(name: 'submitted_count', fromJson: _intFromJson)
  final int submittedCount;

  @JsonKey(name: 'is_group')
  final bool isGroup;

  @JsonKey(name: 'submitted_at', fromJson: _dateTimeFromJson)
  final DateTime? submittedAt;

    @JsonKey(name: 'total_groups', fromJson: _intFromJson)
  final int totalGroups;

  @JsonKey(name: 'submitted_groups', fromJson: _intFromJson)
  final int submittedGroups;

  @JsonKey(fromJson: _educatorsFromJson)
  final List<Map<String, dynamic>>? educators;

  AssignmentModel({
    required this.assignmentId,
    required this.postId,
    required this.title,
    required this.subjectNameTh,
    required this.subjectNameEn,
    required this.assignmentType,
    required this.isGroup,
    this.dueDate,
    this.totalStudents = 0,
    this.submittedCount = 0,
    this.submittedAt,
    this.educators,
    this.totalGroups = 0,
    this.submittedGroups = 0,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) =>
      _$AssignmentModelFromJson(json);
  Map<String, dynamic> toJson() => _$AssignmentModelToJson(this);

  String get subjectName =>
      subjectNameTh.isNotEmpty ? subjectNameTh : subjectNameEn;

  /// Submission status text for student view
  String get studentStatus {
    final now = DateTime.now();
    final isPastDue = dueDate != null && now.isAfter(dueDate!);

    final hasSubmitted = submittedAt != null;

    if (hasSubmitted) {
      if (isPastDue && submittedAt!.isAfter(dueDate!)) {
        return 'ส่งแล้วเกินกำหนด';
      }
      return 'ส่งแล้ว';
    } else {
      if (isPastDue) {
        return 'ยังไม่ส่งเกินกำหนด';
      }
      return 'ยังไม่ส่ง';
    }
  }

  /// Status color using AppColors
  Color get statusColor {
    final now = DateTime.now();
    final isPastDue = dueDate != null && now.isAfter(dueDate!);

    final hasSubmitted = submittedAt != null;
    if (hasSubmitted) {
      if (isPastDue && submittedAt!.isAfter(dueDate!)) {
        return AppColors.assignmentLateSubmitted;
      }
      return AppColors.assignmentSubmitted;
    } else {
      if (isPastDue) {
        return AppColors.assignmentOverdue;
      }
      return AppColors.assignmentNotSubmitted;
    }
  }

  String get teacherSubmissionCount {
    if (isGroup) {
      return '$submittedGroups/$totalGroups';
    } else {
      return '$submittedCount/$totalStudents';
    }
  }
  
}
