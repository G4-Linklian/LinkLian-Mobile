import 'package:get/get.dart';
import '../../../data/repository/assignment_repository.dart';
import '../../../data/model/post_model.dart';
import '../../../data/model/submission_model.dart';
import '../../../core/utils/logger.dart';
import '../../../data/model/assignment_submission_info.dart';
import '../../../core/utils/dialog_helper.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../auth/controller/auth_controller.dart';

class AssignmentSubmissionController extends GetxController {
  final AssignmentRepository repo = Get.find();
  final AuthController authController = Get.find();

  final isLoading = true.obs;

  final post = Rxn<PostModel>();
  final submission = Rxn<SubmissionModel>();
  final assignmentInfo = Rxn<AssignmentSubmissionInfo>();
  final group = Rxn<Map<String, dynamic>>();
  final RxInt currentTab = 0.obs;

  // ===== students =====
  final students = <Map<String, dynamic>>[].obs;
  final filteredStudents = <Map<String, dynamic>>[].obs;

  // =====add : all groups สำหรับ Teacher
  final allGroups = <Map<String, dynamic>>[].obs;
  final isLoadingGroups = false.obs;

  // ===== search & select =====
  final searchKeyword = ''.obs;
  final selectedStudentIds = <int>[].obs;

  // ===== group form =====
  final groupName = ''.obs;

  // ===== loading =====
  final isStudentLoading = false.obs;
  final isSubmittingGroup = false.obs;

  final isEditingGroup = false.obs;

  // ===== original state for edit =====
  final originalGroupName = ''.obs;
  final originalMemberIds = <int>[].obs;

  // pull userId from AuthController
  int? get currentUserId => authController.userId.value;

  bool get isTeacher {
    final roleName = authController.roleName.value?.toLowerCase() ?? '';
    return roleName.contains('teacher') || roleName.contains('instructor');
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    fetchAssignmentPost(args['postId']);
  }

  Future<void> fetchAssignmentPost(int postId) async {
    try {
      isLoading.value = true;
      _resetAllState();

      final result = await repo.getPostAssignment(postId: postId);
      if (result == null) return;

      final postJson = result['post'];
      final assignmentJson = result['assignment'];
      final submissionJson = result['submission'];

      if (postJson == null || assignmentJson == null) return;

      post.value = PostModel.fromJson(postJson);
      assignmentInfo.value = AssignmentSubmissionInfo.fromJson(assignmentJson);
      submission.value = submissionJson != null
          ? SubmissionModel.fromJson(submissionJson)
          : null;

      appLog.info(
        '[GroupAssignment]',
        data: assignmentInfo.value!.toJson(),
        actionPage: 'AssignmentSubmissionController',
      );

      if (assignmentInfo.value!.isGroup) {
        // ✅ Teacher: ดึงกลุ่มทั้งหมด
        if (isTeacher) {
          await fetchAllGroups();
        } else {
          // ✅ Student: ดึงกลุ่มของตัวเอง
          await fetchGroup();

          if (group.value == null && currentUserId != null) {
            selectedStudentIds.add(currentUserId!);
            appLog.info(
              '[Assignment User ]',
              data: currentUserId,
              actionPage: 'AssignmentSubmissionController',
            );
          }

          await fetchStudentsInSection();
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch all groups สำหรับ Teacher
  Future<void> fetchAllGroups() async {
    final assignmentId = assignmentInfo.value?.assignmentId;
    appLog.info(
      '[Assignment ID]',
      data: assignmentId,
      actionPage: 'AssignmentSubmissionController',
    );

    if (assignmentId == null) return;

    try {
      isLoadingGroups.value = true;

      final result = await repo.getAllGroups(assignmentId: assignmentId);

      appLog.info(
        '[Number of group]',
        data: result.length,
        actionPage: 'AssignmentSubmissionController',
      );

      allGroups.assignAll(result);
    } finally {
      isLoadingGroups.value = false;
    }
  }

  // เพิ่ม method reset state ทั้งหมด
  void _resetAllState() {
    // Reset tab
    currentTab.value = 0;

    // Reset group state
    isEditingGroup.value = false;
    group.value = null;

    // Reset form
    groupName.value = '';
    selectedStudentIds.clear();
    searchKeyword.value = '';

    // Reset students
    students.clear();
    filteredStudents.clear();
    allGroups.clear();

    // Reset original state
    originalGroupName.value = '';
    originalMemberIds.clear();

    // Reset loading
    isStudentLoading.value = false;
    isSubmittingGroup.value = false;

    isLoadingGroups.value = false;
  }

  Future<void> fetchGroup() async {
    final assignmentId = assignmentInfo.value?.assignmentId;
    appLog.info(
      '[Assignment ID]',
      data: assignmentId,
      actionPage: 'AssignmentSubmissionController',
    );

    if (assignmentId == null) return;

    final result = await repo.getGroup(assignmentId: assignmentId);
    appLog.info(
      '[Group in this Assignment ID]',
      data: result,
      actionPage: 'AssignmentSubmissionController',
    );

    group.value = result;
  }

  Future<void> fetchStudentsInSection() async {
    final sectionId = post.value?.sectionId;

    if (sectionId == null) return;

    try {
      isStudentLoading.value = true;

      final result = await repo.getStudentsInSection(sectionId: sectionId);

      final activeStudents = result.where((s) {
        return s['user_status'] == 'Active';
      }).toList();

      students.assignAll(activeStudents);
      _applyStudentFilter();
    } finally {
      isStudentLoading.value = false;
    }
  }

  int? _parseUserId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  // ================= FILTER =================

  void onSearchChanged(String value) {
    searchKeyword.value = value;
    _applyStudentFilter();
  }

  void _applyStudentFilter() {
    final keyword = searchKeyword.value.toLowerCase();

    filteredStudents.assignAll(
      students.where((s) {
        final name = '${s['first_name']} ${s['last_name']}'.toLowerCase();

        if (keyword.isNotEmpty && !name.contains(keyword)) {
          return false;
        }

        return true;
      }).toList(),
    );
    ensureCurrentUserIsSelected();

    appLog.info('[Number of student in group]', data: filteredStudents.length);
  }

  // ================= SELECT =================

  void toggleStudent(int userId) {
    if (selectedStudentIds.contains(userId)) {
      selectedStudentIds.remove(userId);
    } else {
      selectedStudentIds.add(userId);
    }

    selectedStudentIds.refresh();

    appLog.info('[Selected student IDs]', data: selectedStudentIds);
  }

  void ensureCurrentUserIsSelected() {
    if (currentUserId != null && !selectedStudentIds.contains(currentUserId)) {
      selectedStudentIds.insert(0, currentUserId!);
      selectedStudentIds.refresh();
      appLog.info(
        '[Auto-added current user to selection]',
        data: currentUserId,
        actionPage: 'AssignmentSubmissionController',
      );
    }
  }

  bool isStudentSelected(int userId) {
    return selectedStudentIds.contains(userId);
  }

  bool isCurrentUser(int userId) {
    return userId == currentUserId;
  }

  // ================= SUBMIT =================

  bool get canSubmitGroup {
    final hasCurrentUser =
        currentUserId != null && selectedStudentIds.contains(currentUserId);

    appLog.info(
      '[Validation check]',
      data: {
        'groupName': groupName.value,
        'selectedStudentIds': selectedStudentIds,
        'hasCurrentUser': hasCurrentUser,
        'isSubmittingGroup': isSubmittingGroup.value,
      },
      actionPage: 'AssignmentSubmissionController',
    );

    return groupName.value.trim().isNotEmpty &&
        selectedStudentIds.isNotEmpty &&
        hasCurrentUser &&
        !isSubmittingGroup.value;
  }

  Future<void> cancelEditingGroupWithConfirm() async {
    if (!hasGroupChanges) {
      _resetEditGroupState();
      return;
    }

    final shouldCancel = await Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.primaryPalette[300],
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ยกเลิกการแก้ไขกลุ่ม?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryPalette[700],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'คุณได้แก้ไขข้อมูลกลุ่มแล้ว\nหากยกเลิก การเปลี่ยนแปลงจะหายไป',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.primaryPalette[700],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPalette[500],
                      ),
                      child: const Text('แก้ไขต่อ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.dangerPalette[500],
                      ),
                      child: const Text('ยกเลิกการแก้ไข'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    if (shouldCancel == true) {
      _resetEditGroupState();
    }
  }

  void _resetEditGroupState() {
    isEditingGroup.value = false;
    groupName.value = '';
    selectedStudentIds.clear();

    if (currentUserId != null) {
      selectedStudentIds.add(currentUserId!);
    }

    originalGroupName.value = '';
    originalMemberIds.clear();
  }

  Future<void> submitGroup() async {
    if (!canSubmitGroup) {
      appLog.error(
        '[Create Group] Cannot submit - validation failed',
        data: {
          'groupName': groupName.value,
          'selectedStudentIds': selectedStudentIds,
          'currentUserId': currentUserId,
        },
        actionPage: 'AssignmentSubmissionController',
        exception: Exception('Validation failed'),
        stackTrace: StackTrace.current,
      );
      return;
    }
    if (currentUserId == null || !selectedStudentIds.contains(currentUserId)) {
      DialogHelper.showNotification(
        title: 'ไม่สามารถบันทึกได้',
        message: 'คุณต้องเป็นสมาชิกในกลุ่มที่สร้าง',
        type: NotificationType.error,
      );
      return;
    }

    try {
      isSubmittingGroup.value = true;

      final assignmentId = assignmentInfo.value!.assignmentId;
      final isUpdate = group.value != null && isEditingGroup.value;

      Map<String, dynamic>? result;

      if (isUpdate) {
        final rawGroupId = group.value!['group_id'];

        int? groupId;
        if (rawGroupId is int) {
          groupId = rawGroupId;
        } else if (rawGroupId is String) {
          groupId = int.tryParse(rawGroupId);
        }

        if (groupId == null) {
          appLog.error(
            '[Invalid Group ID]',
            data: rawGroupId,
            actionPage: 'AssignmentSubmissionController',
            exception: Exception('Invalid group_id format'),
            stackTrace: StackTrace.current,
          );
          throw Exception('Invalid group_id format');
        }

        appLog.debug(
          '[Updating group]', 
          data: {
            'groupId': groupId,
            'assignmentId': assignmentId,
          },
        );

        result = await repo.updateGroup(
          assignmentId: assignmentId,
          groupId: groupId,
          groupName: groupName.value.trim(),
          memberIds: selectedStudentIds.toList(),
        );

        appLog.info('[Update result]', data: result);
      } else {
        appLog.info(
          '[Creating group]',
          data: assignmentId,
          actionPage: 'AssignmentSubmissionController'
          );

        result = await repo.createGroup(
          assignmentId: assignmentId,
          groupName: groupName.value.trim(),
          memberIds: selectedStudentIds.toList(),
        );

        appLog.debug('[Create result]', data: result);
      }

      if (result != null && result['success'] == true) {
        appLog.info('[Response]', data: result.values);

        DialogHelper.showNotification(
          title: 'สำเร็จ!',
          message: isUpdate
              ? 'แก้ไขกลุ่มเรียบร้อยแล้ว'
              : 'สร้างกลุ่มเรียบร้อยแล้ว',
          type: NotificationType.success,
        );

        await fetchGroup();
        isEditingGroup.value = false;
        groupName.value = '';
        selectedStudentIds.clear();
        searchKeyword.value = '';
        originalGroupName.value = '';
        originalMemberIds.clear();

        appLog.info(
          '[Group state reset after submit]',
          data: {
            'groupName': groupName.value,
            'selectedStudentIds': selectedStudentIds,
            'searchKeyword': searchKeyword.value,
          },
          actionPage: 'AssignmentSubmissionController',
        );
      } else {

        DialogHelper.showNotification(
          title: 'ไม่สำเร็จ',
          message: result?['message'] ?? 'ไม่สามารถบันทึกกลุ่มได้',
          type: NotificationType.error,
        );
      }
    } catch (e, stackTrace) {
      appLog.error('[Group Submit Error]', 
      actionPage: 'AssignmentSubmissionController', 
      exception: e, 
      stackTrace: stackTrace);

      String errorMessage = 'ไม่สามารถบันทึกกลุ่มได้';

      if (e.toString().contains('must be a member')) {
        errorMessage = 'คุณต้องเป็นสมาชิกในกลุ่มที่สร้าง';
      } else if (e.toString().contains('cannot remove yourself')) {
        errorMessage = 'คุณไม่สามารถลบตัวเองออกจากกลุ่มได้';
      }

      DialogHelper.showNotification(
        title: 'เกิดข้อผิดพลาด',
        message: errorMessage,
        type: NotificationType.error,
      );
    } finally {
      isSubmittingGroup.value = false;
    }
  }

  void startEditingGroup() {
    final g = group.value;
    if (g == null) return;

    final members = g['members'] as List<dynamic>? ?? [];

    final memberIds = members
        .map((m) => _parseUserId(m['user_sys_id']))
        .whereType<int>()
        .toList();

    groupName.value = g['group_name'] ?? '';
    selectedStudentIds.assignAll(memberIds);
    selectedStudentIds.refresh();

    originalGroupName.value = groupName.value;
    originalMemberIds.assignAll(memberIds);

    isEditingGroup.value = true;
    fetchStudentsInSection();
  }

  bool get hasGroupChanges {
    if (!isEditingGroup.value) return false;

    if (groupName.value.trim() != originalGroupName.value.trim()) {
      return true;
    }

    final current = [...selectedStudentIds]..sort();
    final original = [...originalMemberIds]..sort();

    if (current.length != original.length) return true;

    for (int i = 0; i < current.length; i++) {
      if (current[i] != original[i]) return true;
    }

    return false;
  }

  bool get showGroupTab => assignmentInfo.value?.isGroup == true;
}
