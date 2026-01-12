import 'package:flutter/material.dart';

import '/data/model/class_feed_model.dart';
import '/data/model/class_schedule_model.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/constants/style.dart';
import '../../../core/constants/linklian-icon.dart';
import '../../../core/constants/linklian-bg.dart';

// ============================
// UTILITY FUNCTIONS
// ============================

String dayOfWeekToText(int d) {
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

String formatTime(String time) {
  return time.length >= 5 ? time.substring(0, 5).replaceAll(':', '.') : time;
}

// ============================
// HELPER WIDGETS
// ============================

class _CollapsedSchedule extends StatelessWidget {
  final List<ClassScheduleModel> schedules;

  const _CollapsedSchedule({required this.schedules});

  @override
  Widget build(BuildContext context) {
    
    if (schedules.isEmpty) {
      return Text('ไม่พบตารางเรียน', style: AppTextStyles.descriptionRegular);
    }

    // ถ้ามี 1 วัน → แสดงวัน + เวลา (ความกว้างเท่า expand)
    if (schedules.length == 1) {
      final s = schedules.first;
      return Row(
        children: [
          SizedBox(
            width: 90, // 🔥 ความกว้างเท่า expand
            child: Text(
              dayOfWeekToText(s.dayOfWeek),
              style: AppTextStyles.descriptionRegular,
            ),
          ),
          Text(
            '${formatTime(s.startTime)} - ${formatTime(s.endTime)}',
            style: AppTextStyles.descriptionMedium,
          ),
        ],
      );
    }

    // ถ้ามากกว่า 1 วัน → แสดงแค่วัน
    final days = schedules.map((e) => dayOfWeekToText(e.dayOfWeek)).toSet().toList();

    return Text(
      days.join(', '),
      style: AppTextStyles.descriptionRegular,
    );
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
      key: const ValueKey('expanded_schedule'), // 🔥 Key สำหรับ AnimatedSwitcher
      crossAxisAlignment: CrossAxisAlignment.start,
      children: schedules.map((s) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  dayOfWeekToText(s.dayOfWeek),
                  style: AppTextStyles.descriptionRegular,
                ),
              ),
              Text(
                '${formatTime(s.startTime)} - ${formatTime(s.endTime)}',
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

    final buildingName = schedules.first.building?.buildingName;
    if (buildingName == null || buildingName.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LinkLianIcon.location, size: AppSizes.iconSm),
          const SizedBox(width: AppSizes.xs),
          Text(buildingName, style: AppTextStyles.descriptionMedium),
        ],
      ),
    );
  }
}

// ============================
// MAIN WIDGET
// ============================

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
    final canExpand = schedules.length > 1; // 🔥 ถ้ามี 1 วัน = ไม่สามารถ expand

    return AnimatedSize(
      duration: const Duration(milliseconds: 600), // 🔥 เพิ่มเป็น 600ms (ช้าลง)
      curve: Curves.easeInOutBack, // 🔥 มี bounce effect เล็กน้อย
      alignment: Alignment.topCenter, // 🔥 expand จากด้านบน
      clipBehavior: Clip.none, // 🔥 ให้ bounce ออกนอกขอบได้
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
            padding: const EdgeInsets.only(
              top: AppSizes.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: const [0.0, 0.65, 1.0],
                colors: [
                  AppColors.primaryPalette[500]!.withOpacity(0.2),
                  AppColors.primaryPalette[300]!.withOpacity(0.13),
                  AppColors.primaryPalette[100]!.withOpacity(0.0),
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
                            ? widget.data.sectionName
                            : widget.data.subjectNameTh,
                        style: AppTextStyles.titleBold,
                      ),

                      const SizedBox(height: AppSizes.xs),

                      Text(
                        isTeacher
                            ? widget.data.subjectNameTh
                            : widget.data.sectionName,
                        style: AppTextStyles.descriptionRegular.copyWith(
                          color: AppColors.black.withOpacity(0.6),
                        ),
                      ),

                      const SizedBox(height: AppSizes.sm),

                      // ==================== SEMESTER CHIP ====================
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
                            // 🔥 CHEVRON ICON (แทน classroom)
                            GestureDetector(
                              onTap: canExpand
                                  ? () {
                                      setState(() => isExpanded = !isExpanded);
                                      widget.onTap?.call();
                                    }
                                  : null,
                              child: AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0.0, // 🔥 หมุน 180° เมื่อ expand
                                duration: const Duration(milliseconds: 500), // 🔥 ให้ช้ากว่าการขยายนิดหน่อย
                                curve: Curves.easeInOutBack, // 🔥 มี bounce เล็กน้อย
                                child: Icon(
                                  canExpand
                                      ? LinkLianIcon.expand // เริ่มต้นเป็น chevron_down เสมอ
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
                                alignment: Alignment.topLeft, // 🔥 ชิดซ้ายบน
                                firstChild: SizedBox(
                                  width: double.infinity, // 🔥 บังคับให้มี width
                                  child: _ExpandedSchedule(schedules: schedules),
                                ),
                                secondChild: SizedBox(
                                  width: double.infinity, // 🔥 บังคับให้มี width
                                  child: _CollapsedSchedule(schedules: schedules),
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
    );
  }
}