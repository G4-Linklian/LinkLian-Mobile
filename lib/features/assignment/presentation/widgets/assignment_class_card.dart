import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:palette_generator/palette_generator.dart';

import '../../../classes/data/models/class_feed_model.dart';
import '../../../classes/data/models/class_schedule_model.dart';
import '../../data/models/assignment_model.dart';
import '../../data/repositories/assignment_repository.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/constants/linklian-bg.dart';

class AssignmentClassCard extends StatefulWidget {
  final ClassFeedModel data;
  final String roleName;
  final bool showStudentCount;
  final int? studentCount;
  final VoidCallback? onTap;

  const AssignmentClassCard({
    super.key,
    required this.data,
    required this.roleName,
    this.showStudentCount = false,
    this.studentCount,
    this.onTap,
  });

  @override
  State<AssignmentClassCard> createState() => _AssignmentClassCardState();
}

class _AssignmentClassCardState extends State<AssignmentClassCard> {
  List<AssignmentModel> _assignments = [];
  bool _fetched = false;

  // Default: white (dark overlay on left side is usually dark)
  Color _textColor = Colors.white;

  bool get _isTeacher =>
      widget.roleName == 'teacher' || widget.roleName == 'instructor';

  @override
  void initState() {
    super.initState();
    _analyzeImageColor();
    _fetchAssignments();
  }

  // ─── Palette detection ────────────────────────────────────────────────────

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
          const Color(0xFF1A1A2E);

      // Blend bg with the left-side overlay: primaryPalette[800] at 82%
      // This approximates the effective color users actually see on the left
      final blended = _blendColor(
        bgColor,
        AppColors.primaryPalette[800]!,
        0.82,
      );
      final luminance = blended.computeLuminance();

      if (mounted) {
        setState(() {
          _textColor = luminance > 0.4 ? Colors.black87 : Colors.white;
        });
      }
    } catch (_) {
      // safe default: white
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

  // ─── Fetch assignments ────────────────────────────────────────────────────

  Future<void> _fetchAssignments() async {
    if (!Get.isRegistered<AssignmentRepository>()) return;
    try {
      final repo = Get.find<AssignmentRepository>();
      final result = await repo.getClassAssignments(
        sectionId: widget.data.sectionId,
        role: widget.roleName,
        limit: 20,
      );
      if (mounted) setState(() { _assignments = result; _fetched = true; });
    } catch (_) {
      if (mounted) setState(() => _fetched = true);
    }
  }

  // ─── Student computed stats ───────────────────────────────────────────────

  int get _urgentCount {
    final now = DateTime.now();
    final cutoff = now.add(const Duration(days: 3));
    return _assignments.where((a) =>
      a.submittedAt == null &&
      a.dueDate != null &&
      a.dueDate!.isAfter(now) &&
      a.dueDate!.isBefore(cutoff),
    ).length;
  }

  int get _submittedByMe =>
      _assignments.where((a) => a.submittedAt != null).length;

  // ─── Teacher computed stats ───────────────────────────────────────────────


  int get _waitingReviewCount {
    return _assignments.where((a) {
      final submitted = a.isGroup ? a.submittedGroups : a.submittedCount;
      return submitted > 0;
    }).length;
  }

  List<AssignmentModel> get _upcomingAssignments {
    final now = DateTime.now();
    final cutoff = now.add(const Duration(days: 7));
    return _assignments
        .where((a) =>
            a.dueDate != null &&
            a.dueDate!.isAfter(now) &&
            a.dueDate!.isBefore(cutoff))
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPalette[800]!.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          child: Stack(
            children: [
              // Background image
              Positioned.fill(
                child: Image.network(
                  LinkLianBg.classCardDefault,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: AppColors.primaryPalette[200]),
                ),
              ),
              // Gradient overlay: left → right
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.primaryPalette[800]!.withValues(alpha: 0.82),
                        AppColors.primaryPalette[600]!.withValues(alpha: 0.55),
                        AppColors.primaryPalette[400]!.withValues(alpha: 0.15),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: _isTeacher
                    ? _buildTeacherContent()
                    : _buildStudentContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Student card ─────────────────────────────────────────────────────────

  Widget _buildStudentContent() {
    final schedule = _nextSchedule();
    final total = _assignments.length;
    final submitted = _submittedByMe;
    final urgent = _urgentCount;
    final ratio = total > 0 ? submitted / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.data.subjectNameTh.isNotEmpty
                    ? widget.data.subjectNameTh
                    : widget.data.subjectNameEn,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textColor,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            _semesterBadge(),
          ],
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          widget.data.effectiveClassName,
          style: TextStyle(
            fontSize: 13,
            color: _textColor.withValues(alpha: 0.75),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSizes.sm + 2),

        if (_fetched && total > 0) ...[
          Row(
            children: [
              if (urgent > 0) ...[
                _urgentBadge(urgent),
                const SizedBox(width: AppSizes.sm),
              ],
              Expanded(child: _studentProgressBar(submitted, total, ratio)),
            ],
          ),
          const SizedBox(height: AppSizes.sm + 2),
        ],

        if (_fetched && _upcomingAssignments.isNotEmpty) ...[
          Row(
            children: [
              Text(
                'ใกล้ครบกำหนด',
                style: TextStyle(
                  fontSize: 13,
                  color: _textColor.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              _nearestDuePill(_upcomingAssignments.first),
            ],
          ),
          const SizedBox(height: 4),
          ..._upcomingAssignments.take(2).map((a) => _upcomingRow(a)),
          const SizedBox(height: AppSizes.sm + 2),
        ],

        Row(
          children: [
            _codeChip(widget.data.subjectCode),
            if (schedule != null) ...[
              const SizedBox(width: AppSizes.sm),
              _scheduleChip(schedule),
            ],
          ],
        ),
      ],
    );
  }

  Widget _urgentBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.dangerPalette[500],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'ด่วน $count งาน',
        style: const TextStyle(
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _studentProgressBar(int submitted, int total, double ratio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ส่งแล้ว $submitted/$total งาน',
              style: TextStyle(
                fontSize: 11,
                color: _textColor.withValues(alpha: 0.75),
              ),
            ),
            Text(
              '${(ratio * 100).round()}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 4,
            backgroundColor: _textColor.withValues(alpha: 0.25),
            valueColor: AlwaysStoppedAnimation(_textColor),
          ),
        ),
      ],
    );
  }

  // ─── Teacher card ─────────────────────────────────────────────────────────

  Widget _buildTeacherContent() {
    final total = _assignments.length;
    final waitingReview = _waitingReviewCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title + total assignments badge
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.data.effectiveClassName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _textColor,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            if (_fetched && total > 0) _totalAssignmentsBadge(total),
          ],
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          widget.data.subjectNameTh.isNotEmpty
              ? widget.data.subjectNameTh
              : widget.data.subjectNameEn,
          style: TextStyle(
            fontSize: 16,
            color: _textColor.withValues(alpha: 0.75),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSizes.sm + 2),

        // Status badge
        if (_fetched && waitingReview > 0)
          _teacherBadge('รอตรวจ $waitingReview งาน'),
      ],
    );
  }

  Widget _teacherPendingBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _teacherBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryPalette[200]!,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: AppColors.primaryPalette[900]!,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ─── Shared helpers ───────────────────────────────────────────────────────

  Widget _semesterBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryPalette[400]!,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        widget.data.semester,
        style: TextStyle(
          fontSize: 11,
          color: AppColors.primaryPalette[800]!,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _totalAssignmentsBadge(int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryPalette[400]!,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'งานทั้งหมด $total งาน',
        style: TextStyle(
          fontSize: 11,
          color: AppColors.primaryPalette[800]!,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _nearestDuePill(AssignmentModel a) {
    final daysLeft = a.dueDate!.difference(DateTime.now()).inDays;
    final label = daysLeft == 0
        ? 'วันนี้'
        : daysLeft == 1
            ? 'พรุ่งนี้'
            : 'อีก $daysLeft วัน';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.dangerPalette[300]!,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: AppColors.dangerPalette[500]!,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _upcomingRow(AssignmentModel a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        a.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: _textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _codeChip(String code) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _textColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _textColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        code,
        style: TextStyle(
          fontSize: 11,
          color: _textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _scheduleChip(ClassScheduleModel schedule) {
    final dayName = _dayName(schedule.dayOfWeek);
    final start = schedule.startTime.length >= 5
        ? schedule.startTime.substring(0, 5)
        : schedule.startTime;
    final end = schedule.endTime.length >= 5
        ? schedule.endTime.substring(0, 5)
        : schedule.endTime;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _textColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _textColor.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$dayName $start–$end',
        style: TextStyle(
          fontSize: 11,
          color: _textColor.withValues(alpha: 0.85),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  ClassScheduleModel? _nextSchedule() {
    if (widget.data.schedules.isEmpty) return null;
    final today = DateTime.now().weekday;
    final sorted = [...widget.data.schedules]..sort((a, b) {
      final aDiff = (a.dayOfWeek - today) % 7;
      final bDiff = (b.dayOfWeek - today) % 7;
      return aDiff.compareTo(bDiff);
    });
    return sorted.first;
  }

  String _dayName(int day) {
    const names = {
      1: 'จ.', 2: 'อ.', 3: 'พ.', 4: 'พฤ.', 5: 'ศ.', 6: 'ส.', 7: 'อา.',
    };
    return names[day] ?? '';
  }
}
