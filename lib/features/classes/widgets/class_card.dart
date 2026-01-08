import 'package:flutter/material.dart';

import '/data/model/class_feed_model.dart';
import '/data/model/class_schedule_model.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/constants/style.dart';
import '../../../core/constants/linklian-icon.dart';

class ClassCard extends StatefulWidget {
  final ClassFeedModel data;
  final String roleName;
  final VoidCallback? onTap;

  const ClassCard({
    super.key,
    required this.data,
    required this.roleName,
    this.onTap,
  });

  @override
  State<ClassCard> createState() => _ClassCardState();
}

class _CollapsedSchedule extends StatelessWidget {
  final List<ClassScheduleModel> schedules;

  const _CollapsedSchedule({required this.schedules});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          LinkLianIcon.classroom,
          size: AppSizes.iconSm,
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Text(
            _buildDayOnlyText(schedules),
            style: AppTextStyles.descriptionRegular,
          ),
        ),
      ],
    );
  }

  String _buildDayOnlyText(List<ClassScheduleModel> s) {
    if (s.isEmpty) return 'ไม่พบตารางเรียน';

    final days = s
        .map((e) => _dayOfWeekToText(e.dayOfWeek))
        .toSet()
        .toList();

    return days.join(', ');
  }

  String _dayOfWeekToText(int d) {
    switch (d) {
      case 1:
        return 'วันจันทร์';
      case 2:
        return 'วันอังคาร';
      case 3:
        return 'วันพุธ';
      case 4:
        return 'วันพฤหัส';
      case 5:
        return 'วันศุกร์';
      case 6:
        return 'วันเสาร์';
      case 7:
        return 'วันอาทิตย์';
      default:
        return '';
    }
  }
}

class _ExpandedSchedule extends StatelessWidget {
  final List<ClassScheduleModel> schedules;

  const _ExpandedSchedule({required this.schedules});

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return Text(
        'ไม่พบตารางเรียน',
        style: AppTextStyles.descriptionRegular,
      );
    }

    return Column(
      children: schedules.map((s) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _dayOfWeekToText(s.dayOfWeek),
                  style: AppTextStyles.descriptionRegular,
                ),
              ),
              Text(
                '${_formatTime(s.startTime)} - ${_formatTime(s.endTime)}',
                style: AppTextStyles.descriptionMedium,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _dayOfWeekToText(int d) {
    switch (d) {
      case 1:
        return 'วันจันทร์';
      case 2:
        return 'วันอังคาร';
      case 3:
        return 'วันพุธ';
      case 4:
        return 'วันพฤหัส';
      case 5:
        return 'วันศุกร์';
      case 6:
        return 'วันเสาร์';
      case 7:
        return 'วันอาทิตย์';
      default:
        return '';
    }
  }

  String _formatTime(String time) {
    return time.length >= 5
        ? time.substring(0, 5).replaceAll(':', '.')
        : time;
  }
}

class _LocationText extends StatelessWidget {
  final List<ClassScheduleModel> schedules;

  const _LocationText({required this.schedules});

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) return const SizedBox();

    final first = schedules.first;
    final room = first.room;
    final building = first.building;

    if (room == null && building == null) return const SizedBox();

    final buffer = StringBuffer();

    if (building?.buildingName != null &&
        building!.buildingName.isNotEmpty) {
      buffer.write(building.buildingName);
    }

    if (room?.floor != null) {
      buffer.write(' ชั้น ${room!.floor}');
    }

    if (room?.roomNumber != null &&
        room!.roomNumber!.isNotEmpty) {
      buffer.write(' ห้อง ${room.roomNumber}');
    }

    return Row(
      children: [
        Icon(
          LinkLianIcon.location,
          size: AppSizes.iconSm,
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Text(
            buffer.toString(),
            style: AppTextStyles.descriptionRegular,
          ),
        ),
      ],
    );
  }
}

class _ClassCardState extends State<ClassCard>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false;

  bool get isTeacher =>
      widget.roleName == 'teacher' ||
      widget.roleName == 'instructor';

  bool get isStudent =>
      widget.roleName == 'high school student' ||
      widget.roleName == 'uni student';

  @override
  Widget build(BuildContext context) {
    final schedules = widget.data.schedules;

    return GestureDetector(
      onTap: () {
        setState(() => isExpanded = !isExpanded);
        widget.onTap?.call();
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSizes.md),
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: AppColors.primaryPalette[100],
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ===================================================
              /// TITLE (ROLE BASED)
              /// ===================================================
              Text(
                isTeacher
                    ? widget.data.sectionName
                    : widget.data.subjectNameTh,
                style: AppTextStyles.titleBold,
              ),

              const SizedBox(height: AppSizes.xs),

              Text(
                isTeacher
                    ? widget.data.subjectNameTh
                    : widget.data.sectionName,
                style: AppTextStyles.descriptionRegular
                    .copyWith(color: AppColors.black.withOpacity(0.6)),
              ),

              const SizedBox(height: AppSizes.sm),

              /// ===================================================
              /// SEMESTER CHIP
              /// ===================================================
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: AppSizes.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: Text(
                  'ภาคเรียน ${widget.data.semester}',
                  style: AppTextStyles.descriptionMedium,
                ),
              ),

              const SizedBox(height: AppSizes.md),

              /// ===================================================
              /// SCHEDULE
              /// ===================================================
              isExpanded
                  ? _ExpandedSchedule(schedules: schedules)
                  : _CollapsedSchedule(schedules: schedules),

              const SizedBox(height: AppSizes.sm),

              /// ===================================================
              /// LOCATION
              /// ===================================================
              _LocationText(schedules: schedules),
            ],
          ),
        ),
      ),
    );
  }
}