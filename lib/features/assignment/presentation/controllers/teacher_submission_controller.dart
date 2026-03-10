import 'package:get/get.dart';
import '../../data/repositories/assignment_repository.dart';
import '../../data/repositories/submission_repository.dart';
import '../../data/models/student_submission_status_model.dart';
import '../../data/models/submission_detail_model.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../../../../core/utils/logger.dart';

enum SubmissionFilter { all, submitted, notSubmitted, notSubmittedOverdue }

/// Represents one group's submission state (used for group assignments)
class GroupSubmissionItem {
  final int groupId;
  final String groupName;
  final bool hasSubmitted;
  final int? submissionId;
  final DateTime? submittedAt;
  final double? score;
  final String? feedback;
  final DateTime? markedAt;
  final List<Map<String, dynamic>> members;

  const GroupSubmissionItem({
    required this.groupId,
    required this.groupName,
    required this.hasSubmitted,
    this.submissionId,
    this.submittedAt,
    this.score,
    this.feedback,
    this.markedAt,
    required this.members,
  });
}

class TeacherSubmissionController extends GetxController {
  final AssignmentRepository repo;
  final SubmissionRepository submissionRepo;

  TeacherSubmissionController({
    required this.repo,
    required this.submissionRepo,
  });

  // ─── State ─────────────────────────────────────────────────────────────────
  final isLoading = true.obs;
  final isGrading = false.obs;

  final allStudents = <StudentSubmissionStatusModel>[].obs;
  final filteredStudents = <StudentSubmissionStatusModel>[].obs;

  // Group mode
  final groupedList = <GroupSubmissionItem>[].obs;
  final filteredGroupedList = <GroupSubmissionItem>[].obs;

  final selectedFilter = SubmissionFilter.all.obs;
  final searchKeyword = ''.obs;

  int? assignmentId;
  double? maxScore;
  String? subjectName;
  DateTime? dueDate;

  // For detail page
  final selectedStudent = Rxn<StudentSubmissionStatusModel>();
  final selectedGroup = Rxn<GroupSubmissionItem>();
  final submissionDetail = Rxn<SubmissionDetailModel>();
  final isLoadingDetail = false.obs;

  // Grading form
  final scoreController = ''.obs;
  final feedbackController = ''.obs;

  // ─── Computed ──────────────────────────────────────────────────────────────
  int get submittedCount => allStudents.where((s) => s.hasSubmitted).length;

  int get notSubmittedCount => allStudents.where((s) => !s.hasSubmitted).length;

  bool get _isPastDue =>
      dueDate != null && DateTime.now().isAfter(dueDate!.toLocal());

  bool _isNotSubmittedOverdueStudent(StudentSubmissionStatusModel s) {
    return !s.hasSubmitted && _isPastDue;
  }

  bool _isNotSubmittedOverdueGroup(GroupSubmissionItem g) {
    return !g.hasSubmitted && _isPastDue;
  }

  int get notSubmittedOverdueCount =>
      allStudents.where(_isNotSubmittedOverdueStudent).length;

  int get notSubmittedOverdueGroupCount =>
      groupedList.where(_isNotSubmittedOverdueGroup).length;

  DateTime? _latestDate(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  // ─── Init ──────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    if (assignmentId != null) return;

    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      assignmentId = args['assignmentId'] as int?;
      maxScore = args['maxScore'] != null
          ? (args['maxScore'] as num).toDouble()
          : null;
      if (assignmentId != null) fetchStudents();
    }
  }

  // ─── Fetch ─────────────────────────────────────────────────────────────────
  Future<void> fetchStudents() async {
    if (assignmentId == null) return;
    try {
      isLoading.value = true;
      final result = await repo.getStudentsSubmissionStatus(
        assignmentId: assignmentId!,
      );
      allStudents.assignAll(result);

      _buildGroupedList(result);
      _applyFilters();
    } catch (e) {
      appLog.error('[TeacherSubmission] fetchStudents error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _buildGroupedList(List<StudentSubmissionStatusModel> students) {
    final Map<int, GroupSubmissionItem> groupMap = {};

    for (final s in students) {
      if (s.groupId == null) continue;

      final gid = s.groupId!;
      final existing = groupMap[gid];

      final memberEntry = <String, dynamic>{
        'user_sys_id': s.userSysId,
        'first_name': s.firstName,
        'last_name': s.lastName,
        'profile_pic': s.profilePic,
        'code': s.code,
      };

      if (existing == null) {
        groupMap[gid] = GroupSubmissionItem(
          groupId: gid,
          groupName: s.groupName ?? 'กลุ่ม $gid',
          hasSubmitted:
              s.hasSubmitted || s.submissionId != null || s.submittedAt != null,
          submissionId: s.submissionId,
          submittedAt: s.submittedAt,
          score: s.score,
          feedback: s.feedback,
          markedAt: s.markedAt,
          members: [memberEntry],
        );
      } else {
        final incomingHasSubmitted =
            s.hasSubmitted || s.submissionId != null || s.submittedAt != null;
        final mergedMarkedAt = _latestDate(existing.markedAt, s.markedAt);
        final mergedSubmittedAt = _latestDate(
          existing.submittedAt,
          s.submittedAt,
        );
        final useIncomingGrade =
            s.markedAt != null &&
            (existing.markedAt == null ||
                s.markedAt!.isAfter(existing.markedAt!));
        final useIncomingSubmission =
            s.submissionId != null &&
            (existing.submissionId == null ||
                (s.submittedAt != null &&
                    (existing.submittedAt == null ||
                        s.submittedAt!.isAfter(existing.submittedAt!))) ||
                (s.submittedAt != null &&
                    existing.submittedAt != null &&
                    s.submittedAt!.isAtSameMomentAs(existing.submittedAt!) &&
                    s.submissionId! > existing.submissionId!));

        groupMap[gid] = GroupSubmissionItem(
          groupId: existing.groupId,
          groupName: existing.groupName,
          hasSubmitted: existing.hasSubmitted || incomingHasSubmitted,
          submissionId: useIncomingSubmission
              ? s.submissionId
              : (existing.submissionId ?? s.submissionId),
          submittedAt: mergedSubmittedAt,
          score: useIncomingGrade ? s.score : (existing.score ?? s.score),
          feedback: useIncomingGrade
              ? s.feedback
              : (existing.feedback ?? s.feedback),
          markedAt: mergedMarkedAt,
          members: [...existing.members, memberEntry],
        );
      }
    }

    final sorted = groupMap.values.toList()
      ..sort((a, b) {
        if (a.hasSubmitted && !b.hasSubmitted) return -1;
        if (!a.hasSubmitted && b.hasSubmitted) return 1;
        return a.groupName.compareTo(b.groupName);
      });

    groupedList.assignAll(sorted);
    filteredGroupedList.assignAll(sorted);
  }

  Future<void> fetchSubmissionDetail(int submissionId) async {
    try {
      isLoadingDetail.value = true;
      appLog.info(
        '[TeacherSubmission] fetchSubmissionDetail → submissionId=$submissionId',
      );
      final detail = await repo.getSubmissionDetail(submissionId: submissionId);
      submissionDetail.value = detail;
      appLog.info(
        '[TeacherSubmission] detail loaded: '
        'submissionId=${detail?.submissionId}, '
        'attachments=${detail?.attachments.length ?? 0}',
      );
      if (detail != null) {
        scoreController.value = detail.score?.toString() ?? '';
        feedbackController.value = detail.feedback ?? '';
      }
    } catch (e) {
      appLog.error('[TeacherSubmission] fetchSubmissionDetail error: $e');
    } finally {
      isLoadingDetail.value = false;
    }
  }

  // ─── Filters ───────────────────────────────────────────────────────────────
  void onSearchChanged(String keyword) {
    searchKeyword.value = keyword;
    _applyFilters();
  }

  void changeFilter(SubmissionFilter filter) {
    selectedFilter.value = filter;
    _applyFilters();
  }

  void _applyFilters() {
    final keyword = searchKeyword.value.toLowerCase().trim();

    var studentResult = allStudents.toList();
    switch (selectedFilter.value) {
      case SubmissionFilter.submitted:
        studentResult = studentResult.where((s) => s.hasSubmitted).toList();
        break;
      case SubmissionFilter.notSubmitted:
        studentResult = studentResult.where((s) => !s.hasSubmitted).toList();
        break;
      case SubmissionFilter.notSubmittedOverdue:
        studentResult = studentResult
            .where(_isNotSubmittedOverdueStudent)
            .toList();
        break;
      case SubmissionFilter.all:
        break;
    }
    if (keyword.isNotEmpty) {
      studentResult = studentResult.where((s) {
        return s.displayName.toLowerCase().contains(keyword) ||
            (s.code?.toLowerCase().contains(keyword) ?? false);
      }).toList();
    }
    filteredStudents.assignAll(studentResult);

    var groupResult = groupedList.toList();
    switch (selectedFilter.value) {
      case SubmissionFilter.submitted:
        groupResult = groupResult.where((g) => g.hasSubmitted).toList();
        break;
      case SubmissionFilter.notSubmitted:
        groupResult = groupResult.where((g) => !g.hasSubmitted).toList();
        break;
      case SubmissionFilter.notSubmittedOverdue:
        groupResult = groupResult.where(_isNotSubmittedOverdueGroup).toList();
        break;
      case SubmissionFilter.all:
        break;
    }
    if (keyword.isNotEmpty) {
      groupResult = groupResult.where((g) {
        final nameMatch = g.groupName.toLowerCase().contains(keyword);
        final memberMatch = g.members.any((m) {
          final full = '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'
              .toLowerCase();
          return full.contains(keyword);
        });
        return nameMatch || memberMatch;
      }).toList();
    }
    filteredGroupedList.assignAll(groupResult);
  }

  // ─── Grade ─────────────────────────────────────────────────────────────────
  Future<void> gradeSubmission() async {
    final submissionId = submissionDetail.value?.submissionId;
    if (submissionId == null) return;

    final scoreStr = scoreController.value.trim();
    final score = double.tryParse(scoreStr);

    if (score == null) {
      DialogHelper.showNotification(
        title: 'กรุณากรอกคะแนน',
        message: 'คะแนนต้องเป็นตัวเลข',
        type: NotificationType.error,
      );
      return;
    }

    // ✅ Validate ทศนิยมไม่เกิน 2 ตำแหน่ง
    final decimalRegex = RegExp(r'^\d+(\.\d{1,2})?$');
    if (!decimalRegex.hasMatch(scoreStr)) {
      DialogHelper.showNotification(
        title: 'คะแนนไม่ถูกต้อง',
        message: 'คะแนนต้องเป็นตัวเลข และมีทศนิยมไม่เกิน 2 ตำแหน่ง',
        type: NotificationType.error,
      );
      return;
    }

    // ✅ Resolve maxScore จาก submissionDetail ก่อน แล้วค่อย fallback ไป maxScore
    final resolvedMaxScore = submissionDetail.value?.maxScore ?? maxScore;

    if (resolvedMaxScore != null && score > resolvedMaxScore) {
      DialogHelper.showNotification(
        title: 'คะแนนเกิน',
        message:
            'คะแนนสูงสุดคือ ${resolvedMaxScore % 1 == 0 ? resolvedMaxScore.toInt() : resolvedMaxScore}',
        type: NotificationType.error,
      );
      return;
    }

    try {
      isGrading.value = true;
      final success = await submissionRepo.gradeSubmission(
        submissionId: submissionId,
        score: score,
        feedback: feedbackController.value.trim(),
      );

      if (success) {
        DialogHelper.showNotification(
          title: 'ให้คะแนนสำเร็จ',
          message: 'ให้คะแนนนักเรียนเรียบร้อยแล้ว',
          type: NotificationType.success,
        );
        await fetchSubmissionDetail(submissionId);
        await fetchStudents();
      } else {
        DialogHelper.showNotification(
          title: 'เกิดข้อผิดพลาด',
          message: 'ไม่สามารถให้คะแนนได้',
          type: NotificationType.error,
        );
      }
    } finally {
      isGrading.value = false;
    }
  }

  void selectStudent(StudentSubmissionStatusModel student) {
    selectedStudent.value = student;
    submissionDetail.value = null;
    scoreController.value = '';
    feedbackController.value = '';
    if (student.submissionId != null) {
      fetchSubmissionDetail(student.submissionId!);
    }
  }

  void selectGroup(GroupSubmissionItem group) {
    selectedGroup.value = group;
    submissionDetail.value = null;
    scoreController.value = '';
    feedbackController.value = '';
    if (group.submissionId != null) {
      fetchSubmissionDetail(group.submissionId!);
    }
  }

}
