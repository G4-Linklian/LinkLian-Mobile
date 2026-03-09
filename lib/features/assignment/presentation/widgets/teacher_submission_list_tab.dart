import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/colors.dart';
import '../controllers/assignment_submission_controller.dart';
import '../controllers/teacher_submission_controller.dart';
import '../../data/models/student_submission_status_model.dart';
import '../pages/student_assignment_detail_page.dart';

class TeacherSubmissionListTab extends StatefulWidget {
  final AssignmentSubmissionController controller;

  const TeacherSubmissionListTab({super.key, required this.controller});

  @override
  State<TeacherSubmissionListTab> createState() =>
      _TeacherSubmissionListTabState();
}

class _TeacherSubmissionListTabState extends State<TeacherSubmissionListTab> {
  late TeacherSubmissionController _tc;

  @override
  void initState() {
    super.initState();

    final assignmentId = widget.controller.assignmentInfo.value?.assignmentId;
    final maxScore = widget.controller.assignmentInfo.value?.maxScore;
    final dueDate = widget.controller.assignmentInfo.value?.dueDate;

    if (!Get.isRegistered<TeacherSubmissionController>()) {
      Get.put<TeacherSubmissionController>(
        TeacherSubmissionController(
          repo: widget.controller.repo,
          submissionRepo: widget.controller.submissionRepo,
        ),
      );
      _tc = Get.find<TeacherSubmissionController>();
      _tc.assignmentId = assignmentId;
      _tc.maxScore = maxScore != null ? (maxScore as num).toDouble() : null;
      _tc.subjectName = widget.controller.subjectNameTh.value;
      _tc.dueDate = dueDate;
      if (assignmentId != null) _tc.fetchStudents();
    } else {
      _tc = Get.find<TeacherSubmissionController>();
      if (_tc.assignmentId != assignmentId) {
        _tc.assignmentId = assignmentId;
        _tc.maxScore = maxScore != null ? (maxScore as num).toDouble() : null;
        _tc.subjectName = widget.controller.subjectNameTh.value;
        _tc.dueDate = dueDate;
        if (assignmentId != null) _tc.fetchStudents();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignmentId = widget.controller.assignmentInfo.value?.assignmentId;
    final maxScore = widget.controller.assignmentInfo.value?.maxScore;
    final dueDate = widget.controller.assignmentInfo.value?.dueDate;
    final isGroup = widget.controller.assignmentInfo.value?.isGroup == true;
    final subjectName = _tc.subjectName;
    _tc.dueDate = dueDate;

    if (assignmentId == null) {
      return const Center(child: Text('ไม่พบข้อมูลการบ้าน'));
    }

    return Obx(() {
      if (_tc.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Filter chips ─────────────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(
                  label: 'ทั้งหมด',
                  count: isGroup
                      ? _tc.groupedList.length
                      : _tc.allStudents.length,
                  color: AppColors.primaryPalette[600]!,
                  selected: _tc.selectedFilter.value == SubmissionFilter.all,
                  onTap: () => _tc.changeFilter(SubmissionFilter.all),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'ส่งแล้ว',
                  count: isGroup
                      ? _tc.groupedList.where((g) => g.hasSubmitted).length
                      : _tc.submittedCount,
                  color: Colors.green.shade600,
                  selected:
                      _tc.selectedFilter.value == SubmissionFilter.submitted,
                  onTap: () => _tc.changeFilter(SubmissionFilter.submitted),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'ยังไม่ส่ง',
                  count: isGroup
                      ? _tc.groupedList.where((g) => !g.hasSubmitted).length
                      : _tc.notSubmittedCount,
                  color: Colors.red.shade400,
                  selected:
                      _tc.selectedFilter.value == SubmissionFilter.notSubmitted,
                  onTap: () => _tc.changeFilter(SubmissionFilter.notSubmitted),
                ),
                _StatusChip(
                  label: 'ยังไม่ส่งเกินกำหนด',
                  count: isGroup
                      ? _tc.notSubmittedOverdueGroupCount
                      : _tc.notSubmittedOverdueCount,
                  color: Colors.deepOrange.shade400,
                  selected:
                      _tc.selectedFilter.value ==
                      SubmissionFilter.notSubmittedOverdue,
                  onTap: () =>
                      _tc.changeFilter(SubmissionFilter.notSubmittedOverdue),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ─── Search bar ──────────────────────────────────────────
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryPalette[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: _tc.onSearchChanged,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: isGroup ? 'ค้นหาชื่อกลุ่ม' : 'ค้นหาชื่อ',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              isGroup
                  ? 'ส่งงานแล้ว ${_tc.groupedList.where((g) => g.hasSubmitted).length}/${_tc.groupedList.length} กลุ่ม'
                  : 'ส่งงานแล้ว ${_tc.submittedCount}/${_tc.allStudents.length} คน',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 8),

            // ─── List ────────────────────────────────────────────────
            if (isGroup)
              _buildGroupList(assignmentId, maxScore, subjectName)
            else
              _buildStudentList(assignmentId, maxScore, subjectName),

            const SizedBox(height: 80),
          ],
        ),
      );
    });
  }

  // ─── Group List (งานกลุ่ม) ────────────────────────────────────────────────
  Widget _buildGroupList(
    int assignmentId,
    dynamic maxScore,
    String? subjectName,
  ) {
    final filteredGroups = _tc.filteredGroupedList;

    if (filteredGroups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text('ไม่พบกลุ่ม', style: TextStyle(color: Colors.grey[500])),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: filteredGroups.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
      itemBuilder: (_, index) {
        final group = filteredGroups[index];
        return _GroupTile(
          group: group,
          assignmentId: assignmentId,
          maxScore: maxScore != null ? (maxScore as num).toDouble() : null,
          subjectName: subjectName,
        );
      },
    );
  }

  // ─── Student List (งานเดี่ยว) ─────────────────────────────────────────────
  Widget _buildStudentList(
    int assignmentId,
    dynamic maxScore,
    String? subjectName,
  ) {
    if (_tc.filteredStudents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'ไม่พบนักเรียน',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _tc.filteredStudents.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: Colors.grey[200], indent: 64),
      itemBuilder: (_, index) {
        final student = _tc.filteredStudents[index];
        return _StudentListTile(
          student: student,
          maxScore: maxScore != null ? (maxScore as num).toDouble() : null,
          assignmentId: assignmentId,
          subjectName: subjectName,
        );
      },
    );
  }
}

// ─── Group Tile with expand/collapse ─────────────────────────────────────────
class _GroupTile extends StatefulWidget {
  final GroupSubmissionItem group;
  final int assignmentId;
  final double? maxScore;
  final String? subjectName;

  const _GroupTile({
    required this.group,
    required this.assignmentId,
    required this.maxScore,
    this.subjectName,
  });

  @override
  State<_GroupTile> createState() => _GroupTileState();
}

class _GroupTileState extends State<_GroupTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final hasSubmitted = g.hasSubmitted;
    final isMarked =
        g.markedAt != null ||
        g.score != null ||
        (g.feedback?.trim().isNotEmpty ?? false);

    return Column(
      children: [
        // ─── Group header row ────────────────────────────────────────
        InkWell(
          onTap: () {
            Get.to(
              () => const StudentAssignmentDetailPage(),
              arguments: {
                'groupItem': g,
                'assignmentId': widget.assignmentId,
                'maxScore': widget.maxScore,
                'isGroup': true,
                'subjectName': widget.subjectName,
              },
              transition: Transition.rightToLeft,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                // Group avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryPalette[200],
                  child: Text(
                    g.groupName.isNotEmpty ? g.groupName[0] : 'G',
                    style: TextStyle(
                      color: AppColors.primaryPalette[700],
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.groupName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.black,
                        ),
                      ),
                      Text(
                        '${g.members.length} คน',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                // Status badge
                _GroupStatusBadge(
                  hasSubmitted: hasSubmitted,
                  isMarked: isMarked,
                ),
                const SizedBox(width: 8),
                // Expand toggle
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ─── Member list (collapsed by default) ──────────────────────
        if (_expanded)
          Container(
            margin: const EdgeInsets.only(left: 56, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryPalette[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: g.members.asMap().entries.map((entry) {
                final i = entry.key;
                final m = entry.value;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          _buildMemberAvatar(m),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'
                                  .trim(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < g.members.length - 1)
                      Divider(height: 1, color: Colors.grey[200], indent: 44),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildMemberAvatar(Map<String, dynamic> m) {
    final pic = m['profile_pic'] as String?;
    final first = (m['first_name'] as String? ?? '');
    if (pic != null && pic.isNotEmpty) {
      return CircleAvatar(radius: 16, backgroundImage: NetworkImage(pic));
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.primaryPalette[200],
      child: Text(
        first.isNotEmpty ? first[0] : '?',
        style: TextStyle(
          color: AppColors.primaryPalette[700],
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GroupStatusBadge extends StatelessWidget {
  final bool hasSubmitted;
  final bool isMarked;

  const _GroupStatusBadge({required this.hasSubmitted, required this.isMarked});

  @override
  Widget build(BuildContext context) {
    if (!hasSubmitted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          'ยังไม่ส่ง',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    if (isMarked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Text(
          'ให้คะแนนแล้ว',
          style: TextStyle(
            fontSize: 11,
            color: Colors.green.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryPalette[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryPalette[300]!),
      ),
      child: Text(
        'ส่งแล้ว',
        style: TextStyle(
          fontSize: 11,
          color: AppColors.primaryPalette[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── Status Chip ─────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected ? color : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: selected ? color : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Student List Tile (งานเดี่ยว) ───────────────────────────────────────────
class _StudentListTile extends StatelessWidget {
  final StudentSubmissionStatusModel student;
  final double? maxScore;
  final int assignmentId;
  final String? subjectName;

  const _StudentListTile({
    required this.student,
    required this.maxScore,
    required this.assignmentId,
    this.subjectName,
  });

  String _formatTime(DateTime dt) =>
      DateFormat('HH:mm • dd/MM/yy', 'th').format(dt);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.to(
          () => const StudentAssignmentDetailPage(),
          arguments: {
            'student': student,
            'assignmentId': assignmentId,
            'maxScore': maxScore,
            'isGroup': false,
            'subjectName': subjectName,
          },
          transition: Transition.rightToLeft,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: AppColors.black,
                    ),
                  ),
                  if (student.submittedAt != null)
                    Text(
                      'ส่งเมื่อ ${_formatTime(student.submittedAt!)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                ],
              ),
            ),
            _buildStatusBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (student.profilePic != null && student.profilePic!.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(student.profilePic!),
      );
    }
    final initial = student.firstName.isNotEmpty ? student.firstName[0] : '?';
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.primaryPalette[200],
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.primaryPalette[700],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (!student.hasSubmitted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          'ยังไม่ส่ง',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    if (student.isGraded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Text(
          'ให้คะแนนแล้ว',
          style: TextStyle(
            fontSize: 12,
            color: Colors.green.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryPalette[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryPalette[300]!),
      ),
      child: Text(
        'ส่งแล้ว',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.primaryPalette[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
