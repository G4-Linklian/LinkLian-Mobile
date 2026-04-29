import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import '../../data/models/class_feed_model.dart';
import '../../data/models/class_schedule_model.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/constants/style.dart';
import '../../../../core/constants/linklian-icon.dart';
import '../../../../core/constants/linklian-bg.dart';
import '../../../../core/utils/formatter.dart';

class ClassCardSkeleton extends StatefulWidget {
  const ClassCardSkeleton({super.key});

  @override
  State<ClassCardSkeleton> createState() => _ClassCardSkeletonState();
}

class _ClassCardSkeletonState extends State<ClassCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bar({required double width, double height = 14}) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF9E9E9E),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      decoration: BoxDecoration(
        color: const Color(0xFFBDBDBD),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title area
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.md,
              AppSizes.md,
              AppSizes.md,
              AppSizes.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBuilder(
                  animation: _opacity,
                  builder: (_, child) => Opacity(
                    opacity: _opacity.value,
                    child: Text(
                      'กำลังโหลด...',
                      style: AppTextStyles.titleBold.copyWith(
                        color: const Color(0xFF757575),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                _bar(width: screenWidth * 0.38),
                const SizedBox(height: AppSizes.md),
              ],
            ),
          ),

          // Schedule bar
          Container(
            padding: const EdgeInsets.all(AppSizes.sm),
            decoration: BoxDecoration(
              color: const Color(0xFF9E9E9E),
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            ),
            child: Row(
              children: [
                _bar(width: AppSizes.md, height: AppSizes.md),
                const SizedBox(width: AppSizes.sm),
                _bar(width: screenWidth * 0.3),
                const Spacer(),
                _bar(width: screenWidth * 0.15, height: 26),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


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
  Color _textColor = const Color(0xFF757575);

  bool get isTeacher =>
      widget.roleName == 'teacher' || widget.roleName == 'instructor';

  bool get isStudent =>
      widget.roleName == 'high school student' ||
      widget.roleName == 'uni student';

  @override
  void initState() {
    super.initState();
    _analyzeImageColor();
  }

  Future<void> _analyzeImageColor() async {
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(LinkLianBg.classCardDefault),
        maximumColorCount: 16,
      );

      final bgColor =
          palette.dominantColor?.color ??
          palette.vibrantColor?.color ??
          palette.mutedColor?.color ??
          const Color(0xFFCCBFA0);

      // Gradient ที่ top ของ card (บริเวณ title/subtitle) มี opacity = 0.0
      // จึงใช้ raw dominant color โดยตรง ไม่ต้อง blend
      final effectiveLuminance = bgColor.computeLuminance();

      // > 0.4 → background สว่าง → text ดำ
      // ≤ 0.4 → background มืด  → text ขาว
      final useLightText = effectiveLuminance <= 0.4;

      if (mounted) {
        setState(() {
          _textColor = useLightText ? Colors.white : Colors.black87;
        });
      }
    } catch (_) {
      // safe default: white text
    }
  }

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
                        style: AppTextStyles.titleBold.copyWith(color: _textColor),
                      ),

                      const SizedBox(height: AppSizes.xs),

                      Text(
                        isTeacher
                            ? widget.data.subjectNameTh
                            : widget.data.effectiveClassName,
                        style: AppTextStyles.paragraphBold.copyWith(
                          color: _textColor.withValues(alpha: 0.7),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ========== LEFT: CHEVRON + DAY + TIME ==========
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
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
