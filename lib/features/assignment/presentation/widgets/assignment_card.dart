import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../data/models/assignment_model.dart';
import '../../../../core/constants/linklian-bg.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/linklian-icon.dart';

// ─── AssignmentCardSkeleton ───────────────────────────────────────────────────

class AssignmentCardSkeleton extends StatefulWidget {
  const AssignmentCardSkeleton({super.key});

  @override
  State<AssignmentCardSkeleton> createState() => _AssignmentCardSkeletonState();
}

class _AssignmentCardSkeletonState extends State<AssignmentCardSkeleton>
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
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      height: 150,
      decoration: BoxDecoration(
        color: const Color(0xFFBDBDBD),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + subject badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bar(width: sw * 0.45),
                    const SizedBox(height: 4),
                    _bar(width: sw * 0.32),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _bar(width: 64, height: 26),
            ],
          ),
          const Spacer(),
          // Due date row
          Row(
            children: [
              _bar(width: 14, height: 14),
              const SizedBox(width: 4),
              _bar(width: sw * 0.3),
            ],
          ),
          const Spacer(),
          // Bottom pills
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _bar(width: 72, height: 26),
              _bar(width: 72, height: 26),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── AssignmentCard ───────────────────────────────────────────────────────────

class AssignmentCard extends StatefulWidget {
  final AssignmentModel assignment;
  final bool isTeacher;
  final VoidCallback? onTap;

  const AssignmentCard({
    super.key,
    required this.assignment,
    this.isTeacher = false,
    this.onTap,
  });

  @override
  State<AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<AssignmentCard> {
  Color _textColor = Colors.black54;

  AssignmentModel get assignment => widget.assignment;
  bool get isTeacher => widget.isTeacher;

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

      // Gradient overlay: primaryPalette[300] = 0xFFFFCF9A
      // ใช้ opacity 0.60 เพื่อให้ warm overlay มีน้ำหนักเพียงพอต่อ luminance
      final blended = _blendColor(bgColor, const Color(0xFFFFCF9A), 0.60);
      final effectiveLuminance = blended.computeLuminance();

      if (mounted) {
        setState(() {
          _textColor =
              effectiveLuminance > 0.4 ? Colors.black : Colors.white;
        });
      }
    } catch (_) {
      // keep default Colors.black54
    }
  }

  Color _blendColor(Color src, Color dst, double dstOpacity) {
    final r = (src.r * 255 * (1 - dstOpacity) + dst.r * 255 * dstOpacity)
        .round()
        .clamp(0, 255);
    final g = (src.g * 255 * (1 - dstOpacity) + dst.g * 255 * dstOpacity)
        .round()
        .clamp(0, 255);
    final b = (src.b * 255 * (1 - dstOpacity) + dst.b * 255 * dstOpacity)
        .round()
        .clamp(0, 255);
    return Color.fromARGB(255, r, g, b);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPalette[800]!.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background image
              SizedBox(
                width: double.infinity,
                height: isTeacher ? 140 : 150,
                child: Image.network(
                  LinkLianBg.classCardDefault,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: AppColors.primaryPalette[100]),
                ),
              ),
              // Primary overlay base
              Container(
                width: double.infinity,
                height: isTeacher ? 140 : 150,
                color: AppColors.primaryPalette[200]!.withValues(alpha: 0.05),
              ),
              // Gradient overlay (top to bottom)
              Container(
                width: double.infinity,
                height: isTeacher ? 140 : 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryPalette[300]!.withValues(alpha: 0.2),
                      AppColors.primaryPalette[300]!.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
              // Content
              Container(
                width: double.infinity,
                height: isTeacher ? 140 : 150,
                padding: const EdgeInsets.all(14),
                child: isTeacher
                    ? _buildTeacherContent()
                    : _buildStudentContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Student card: title, subject, dueDate, assignmentType, status
  Widget _buildStudentContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title + Subject badge
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Tooltip(
                message: assignment.title,
                triggerMode: TooltipTriggerMode.longPress,
                preferBelow: false,
                textStyle: TextStyle(fontSize: 14, color: AppColors.primaryPalette[900]),
                decoration: BoxDecoration(
                  color: AppColors.primaryPalette[200]!.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  assignment.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _subjectBadge(),
          ],
        ),
        const Spacer(),
        // Due date row
        if (assignment.dueDate != null)
          Row(
            children: [
              Icon(
                LinkLianIcon.clock,
                size: 14,
                color: _textColor,
              ),
              const SizedBox(width: 4),
              Text(
                'กำหนด : ${_formatDueDate(assignment.dueDate!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: _textColor,
                ),
              ),
            ],
          ),
        const Spacer(),
        // Bottom: assignment type + status
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _pill(assignment.assignmentType, AppColors.primaryPalette[700]!),
            _pill(
              _displayStudentStatus(assignment.studentStatus),
              _statusColorForDisplay(assignment.studentStatus),
            ),
          ],
        ),
      ],
    );
  }

  /// Teacher card: title, subject, dueDate, submitted/total
  Widget _buildTeacherContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title + Subject badge
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Tooltip(
                message: assignment.title,
                triggerMode: TooltipTriggerMode.longPress,
                preferBelow: false,
                child: Text(
                  assignment.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _subjectBadge(),
          ],
        ),
        const Spacer(),
        // Due date row
        if (assignment.dueDate != null)
          Row(
            children: [
              Icon(
                LinkLianIcon.clock,
                size: 14,
                color: _textColor,
              ),
              const SizedBox(width: 4),
              Text(
                'กำหนด : ${_formatDueDate(assignment.dueDate!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: _textColor,
                ),
              ),
            ],
          ),
        const Spacer(),
        // Bottom: assignment type + submission count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ✅ แสดงประเภทงาน (งานกลุ่ม/งานเดี่ยว)
            _pill(assignment.assignmentType, AppColors.primaryPalette[700]!),

            // ✅ แสดงจำนวนที่ส่ง (กลุ่มหรือคน)
            Row(
              children: [
                Icon(
                  assignment.isGroup ? Icons.groups : LinkLianIcon.users,
                  size: 18,
                  color: AppColors.primaryPalette[600]!,
                ),
                const SizedBox(width: 8),
                _pill(
                  assignment.teacherSubmissionCount,
                  AppColors.primaryPalette[600]!,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _subjectBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryPalette[400]!,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        assignment.subjectName,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.primaryPalette[800]!,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    final isSubmitted = text == 'ส่งแล้ว';
    final isNotSubmitted = text == 'ยังไม่ส่ง';
    final isOverdue = color == AppColors.dangerPalette[500];

    final bgColor = isSubmitted
        ? AppColors.successPalette[500]!
        : isNotSubmitted
            ? AppColors.gray
            : color;
    final textColor = isSubmitted
        ? AppColors.successPalette[900]!
        : isNotSubmitted
            ? const Color.fromARGB(255, 157, 157, 157)
        : isOverdue
            ? AppColors.white
            : AppColors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final localDate = date.toLocal();
    final buddhistYear = localDate.year + 543;
    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final yearShort = (buddhistYear % 100).toString().padLeft(2, '0');
    final time = DateFormat('HH:mm').format(localDate);
    return '$day/$month/$yearShort $time น.';
  }

  String _displayStudentStatus(String rawStatus) {
    switch (rawStatus) {
      case 'ยังไม่ส่งเกินกำหนด':
      case 'ส่งแล้วเกินกำหนด':
        return 'เกินกำหนดส่ง';
      default:
        return rawStatus;
    }
  }

  Color _statusColorForDisplay(String rawStatus) {
    switch (rawStatus) {
      case 'ยังไม่ส่ง':
        return AppColors.gray;
      case 'ยังไม่ส่งเกินกำหนด':
      case 'ส่งแล้วเกินกำหนด':
        return AppColors.dangerPalette[500]!;
      case 'ส่งแล้ว':
        return AppColors.successPalette[500]!;
      default:
        return assignment.statusColor;
    }
  }
}
