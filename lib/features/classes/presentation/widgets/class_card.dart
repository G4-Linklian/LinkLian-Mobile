import 'package:flutter/material.dart';

import '../../data/models/class_feed_model.dart';
import '../../data/models/class_schedule_model.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/constants/style.dart';
import '../../../../core/constants/linklian-icon.dart';
import '../../../../core/constants/linklian-bg.dart';
import '../../../../core/utils/formatter.dart';


class _CollapsedSchedule extends StatelessWidget {
  final List<ClassScheduleModel> schedules;

  const _CollapsedSchedule({required this.schedules});

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return Text('ไม่พบตารางเรียน', style: AppTextStyles.descriptionRegular);
    }

    if (schedules.length == 1) {
      final s = schedules.first;
      return Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              Formatter.dayOfWeekToText(s.dayOfWeek),
              style: AppTextStyles.descriptionRegular,
            ),
          ),
          Text(
            '${Formatter.formatTime(s.startTime)} - ${Formatter.formatTime(s.endTime)}',
            style: AppTextStyles.descriptionMedium,
          ),
        ],
      );
    }

    final days = schedules
        .map((e) => Formatter.dayOfWeekToText(e.dayOfWeek))
        .toSet()
        .toList();

    return Text(days.join(', '), style: AppTextStyles.descriptionRegular);
  }
}

class _ExpandedSchedule extends StatelessWidget {
  final List<ClassScheduleModel> schedules;

  const _ExpandedSchedule({required this.schedules});

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return Text('ไม่พบตารางเรียน', style: AppTextStyles.descriptionRegular);
    }

    return Column(
      key: const ValueKey('expanded_schedule'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: schedules.map((s) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  Formatter.dayOfWeekToText(s.dayOfWeek),
                  style: AppTextStyles.descriptionRegular,
                ),
              ),
              Text(
                '${Formatter.formatTime(s.startTime)} - ${Formatter.formatTime(s.endTime)}',
                style: AppTextStyles.descriptionMedium,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _LocationChip extends StatelessWidget {
  final List<ClassScheduleModel> schedules;

  const _LocationChip({required this.schedules});

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) return const SizedBox();

    final roomNumber = schedules.first.room?.roomNumber;
    if (roomNumber == null || roomNumber.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LinkLianIcon.location, size: AppSizes.iconSm),
          const SizedBox(width: AppSizes.xs),
          Text(
            roomNumber,
            style: AppTextStyles.descriptionMedium,
          ),
        ],
      ),
    );
  }
}

class ClassCard extends StatefulWidget {
  final ClassFeedModel data;
  final String roleName;
  final bool showStudentCount;
  final int? studentCount;
  final VoidCallback? onTap;

  const ClassCard({
    super.key,
    required this.data,
    required this.roleName,
    this.showStudentCount = false,
    this.studentCount,
    this.onTap,
  });

  @override
  State<ClassCard> createState() => _ClassCardState();
}

class _ClassCardState extends State<ClassCard> {
  bool isExpanded = false;

  bool get isTeacher =>
      widget.roleName == 'teacher' || widget.roleName == 'instructor';

  bool get isStudent =>
      widget.roleName == 'high school student' ||
      widget.roleName == 'uni student';

  @override
  Widget build(BuildContext context) {
    final schedules = widget.data.schedules;
    final canExpand = schedules.length > 1;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutBack,
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSizes.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            image: DecorationImage(
              image: NetworkImage(LinkLianBg.classCardDefault),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.only(top: AppSizes.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: const [0.0, 0.65, 1.0],
                colors: [
                  AppColors.primaryPalette[500]!.withValues(alpha: 0.2),
                  AppColors.primaryPalette[300]!.withValues(alpha: 0.13),
                  AppColors.primaryPalette[100]!.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================== TITLE ====================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTeacher
                            ? widget.data.effectiveClassName
                            : widget.data.subjectNameTh,
                        style: AppTextStyles.titleBold,
                      ),

                      const SizedBox(height: AppSizes.xs),

                      Text(
                        isTeacher
                            ? widget.data.subjectNameTh
                            : widget.data.effectiveClassName,
                        style: AppTextStyles.descriptionRegular.copyWith(
                          color: AppColors.black.withValues(alpha: 0.6),
                        ),
                      ),

                      const SizedBox(height: AppSizes.sm),

                      // ==================== SEMESTER CHIP ====================
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.sm,
                              vertical: AppSizes.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusLg,
                              ),
                            ),
                            child: Text(
                              'ภาคเรียน ${widget.data.semester}',
                              style: AppTextStyles.descriptionMedium,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSizes.md),
                    ],
                  ),
                ),

                // ==================== SCHEDULE + LOCATION ====================
                Container(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFCF9A),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(AppSizes.radiusXl),
                      bottomRight: Radius.circular(AppSizes.radiusXl),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ========== LEFT: CHEVRON + DAY + TIME ==========
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: canExpand
                                  ? () {
                                      setState(() => isExpanded = !isExpanded);
                                    }
                                  : null,
                              child: AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOutBack,
                                child: Icon(
                                  canExpand
                                      ? LinkLianIcon.expand
                                      : LinkLianIcon.classroom,
                                  size: AppSizes.iconSm,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSizes.sm),
                            Expanded(
                              child: AnimatedCrossFade(
                                duration: const Duration(milliseconds: 350),
                                firstCurve: Curves.easeOutCubic,
                                secondCurve: Curves.easeOutCubic,
                                sizeCurve: Curves.easeInOutCubic,
                                crossFadeState: isExpanded
                                    ? CrossFadeState.showFirst
                                    : CrossFadeState.showSecond,
                                alignment: Alignment.topLeft,
                                firstChild: SizedBox(
                                  width: double.infinity,
                                  child: _ExpandedSchedule(
                                    schedules: schedules,
                                  ),
                                ),
                                secondChild: SizedBox(
                                  width: double.infinity,
                                  child: _CollapsedSchedule(
                                    schedules: schedules,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: AppSizes.md),

                      // ========== RIGHT: LOCATION ==========
                      _LocationChip(schedules: schedules),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
