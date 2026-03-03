import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/repositories/assignment_repository.dart';
import '../../data/repositories/submission_repository.dart';
import '../../data/models/group_model.dart';
import '../../../shared/models/post_model.dart';
import '../../data/models/submission_model.dart';
import '../../../../core/utils/logger.dart';
import '../../data/models/assignment_submission_info.dart';
import '../../../../core/utils/dialog_helper.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../auth/controller/auth_controller.dart';

class AssignmentSubmissionController extends GetxController {
  final AssignmentRepository repo = Get.find();
  final SubmissionRepository submissionRepo = Get.find();
  final AuthController authController = Get.find();

  final isLoading = true.obs;

  final post = Rxn<PostModel>();
  final submission = Rxn<SubmissionModel>();
  final assignmentInfo = Rxn<AssignmentSubmissionInfo>();

  // ===== group =====
  final group = Rxn<GroupModel>();
  final allGroups = <GroupModel>[].obs;
  final isLoadingGroups = false.obs;

  final RxInt currentTab = 0.obs;

  // ===== students =====
  final students = <Map<String, dynamic>>[].obs;
  final filteredStudents = <Map<String, dynamic>>[].obs;

  // ===== search & select =====
  final searchKeyword = ''.obs;
  final selectedStudentIds = <int>[].obs;

  // ===== group form =====
  final groupName = ''.obs;

  // ===== loading =====
  final isStudentLoading = false.obs;
  final isSubmittingGroup = false.obs;
  final isEditingGroup = false.obs;

  // ===== submission =====
  final uploadedFiles = <Map<String, dynamic>>[].obs;
  final existingSubmission = Rxn<Map<String, dynamic>>();
  final isSubmittingWork = false.obs;

  // ===== original state for edit =====
  final originalGroupName = ''.obs;
  final originalMemberIds = <int>[].obs;

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

      final result = await repo.getPostAssignment(
        postId: postId,
        role: authController.roleName.value,
      );
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

      if (submissionJson != null) {
        existingSubmission.value = Map<String, dynamic>.from(submissionJson);
        appLog.info(' existingSubmission loaded: submission_id=${existingSubmission.value?['submission_id']}');

        final submissionId = _parseInt(submissionJson['submission_id']);
        if (submissionId != null) {
          await _loadExistingSubmissionFiles(submissionId);
        }
      }

      appLog.info(' isGroup = ${assignmentInfo.value!.isGroup}');

      if (assignmentInfo.value!.isGroup) {
        if (isTeacher) {
          await fetchAllGroups();
        } else {
          await fetchGroup();
          if (group.value == null && currentUserId != null) {
            selectedStudentIds.add(currentUserId!);
          }
          await fetchStudentsInSection();
        }
      } else {
        if (!isTeacher) {
          await fetchGroup();
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchAllGroups() async {
    final assignmentId = assignmentInfo.value?.assignmentId;
    if (assignmentId == null) return;

    try {
      isLoadingGroups.value = true;
      final result = await repo.getAllGroups(assignmentId: assignmentId);
      appLog.info('Fetched ${result.length} groups');
      allGroups.assignAll(result);
    } finally {
      isLoadingGroups.value = false;
    }
  }

  Future<void> fetchGroup() async {
    final assignmentId = assignmentInfo.value?.assignmentId;
    appLog.info('fetchGroup assignmentId = $assignmentId');
    if (assignmentId == null) return;

    final result = await repo.getGroup(assignmentId: assignmentId);
    appLog.info('getGroup result = $result');
    group.value = result;
  }

  Future<void> fetchStudentsInSection() async {
    final sectionId = post.value?.sectionId;
    if (sectionId == null) return;

    try {
      isStudentLoading.value = true;
      final result = await repo.getStudentsInSection(sectionId: sectionId);
      final activeStudents = result.where((s) => s['user_status'] == 'Active').toList();
      students.assignAll(activeStudents);
      _applyStudentFilter();
    } finally {
      isStudentLoading.value = false;
    }
  }

  void _resetAllState() {
    currentTab.value = 0;
    isEditingGroup.value = false;
    group.value = null;
    groupName.value = '';
    selectedStudentIds.clear();
    searchKeyword.value = '';
    students.clear();
    filteredStudents.clear();
    allGroups.clear();
    originalGroupName.value = '';
    originalMemberIds.clear();
    isStudentLoading.value = false;
    isSubmittingGroup.value = false;
    isLoadingGroups.value = false;
    uploadedFiles.clear();
    existingSubmission.value = null;
    isSubmittingWork.value = false;
  }

  int? _parseInt(dynamic value) {
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
        return keyword.isEmpty || name.contains(keyword);
      }).toList(),
    );
    ensureCurrentUserIsSelected();
    appLog.info('🔍 filteredStudents = ${filteredStudents.length}');
  }

  // ================= SELECT =================

  void toggleStudent(int userId) {
    if (selectedStudentIds.contains(userId)) {
      selectedStudentIds.remove(userId);
    } else {
      selectedStudentIds.add(userId);
    }
    selectedStudentIds.refresh();
    appLog.info('Selected IDs: $selectedStudentIds');
  }

  void ensureCurrentUserIsSelected() {
    if (currentUserId != null && !selectedStudentIds.contains(currentUserId)) {
      selectedStudentIds.insert(0, currentUserId!);
      selectedStudentIds.refresh();
      appLog.info('Auto-added current user to selection');
    }
  }

  bool isStudentSelected(int userId) => selectedStudentIds.contains(userId);
  bool isCurrentUser(int userId) => userId == currentUserId;

  // ================= GROUP SUBMIT =================

  bool get canSubmitGroup {
    final hasCurrentUser = currentUserId != null &&
        selectedStudentIds.contains(currentUserId);
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
              Text('ยกเลิกการแก้ไขกลุ่ม?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primaryPalette[700])),
              const SizedBox(height: 16),
              Text('คุณได้แก้ไขข้อมูลกลุ่มแล้ว\nหากยกเลิก การเปลี่ยนแปลงจะหายไป',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.primaryPalette[700])),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: false),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPalette[500]),
                      child: const Text('แก้ไขต่อ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerPalette[500]),
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

    if (shouldCancel == true) _resetEditGroupState();
  }

  void _resetEditGroupState() {
    isEditingGroup.value = false;
    groupName.value = '';
    selectedStudentIds.clear();
    if (currentUserId != null) selectedStudentIds.add(currentUserId!);
    originalGroupName.value = '';
    originalMemberIds.clear();
  }

  Future<void> submitGroup() async {
    if (!canSubmitGroup) return;

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
      bool success = false;

      if (isUpdate) {
        final groupId = group.value!.groupId;
        if (groupId == null) throw Exception('Invalid group_id');

        success = await repo.updateGroup(
          assignmentId: assignmentId,
          groupId: groupId,
          groupName: groupName.value.trim(),
          memberIds: selectedStudentIds.toList(),
        );
      } else {
        success = await repo.createGroup(
          assignmentId: assignmentId,
          groupName: groupName.value.trim(),
          memberIds: selectedStudentIds.toList(),
        );
      }

      if (success) {
        DialogHelper.showNotification(
          title: 'สำเร็จ!',
          message: isUpdate ? 'แก้ไขกลุ่มเรียบร้อยแล้ว' : 'สร้างกลุ่มเรียบร้อยแล้ว',
          type: NotificationType.success,
        );
        await fetchGroup();
        isEditingGroup.value = false;
        groupName.value = '';
        selectedStudentIds.clear();
        searchKeyword.value = '';
        originalGroupName.value = '';
        originalMemberIds.clear();
      } else {
        DialogHelper.showNotification(
          title: 'ไม่สำเร็จ',
          message: 'ไม่สามารถบันทึกกลุ่มได้',
          type: NotificationType.error,
        );
      }
    } catch (e, stackTrace) {
      appLog.info('submitGroup error: $e\n$stackTrace');
      String errorMessage = 'ไม่สามารถบันทึกกลุ่มได้';
      if (e.toString().contains('must be a member')) errorMessage = 'คุณต้องเป็นสมาชิกในกลุ่มที่สร้าง';
      else if (e.toString().contains('cannot remove yourself')) errorMessage = 'คุณไม่สามารถลบตัวเองออกจากกลุ่มได้';
      DialogHelper.showNotification(title: 'เกิดข้อผิดพลาด', message: errorMessage, type: NotificationType.error);
    } finally {
      isSubmittingGroup.value = false;
    }
  }

  void startEditingGroup() {
    final g = group.value;
    if (g == null) return;

    final memberIds = g.members
        .map((m) => m.userSysId)
        .whereType<int>()
        .toList();

    groupName.value = g.groupName;
    selectedStudentIds.assignAll(memberIds);
    selectedStudentIds.refresh();
    originalGroupName.value = groupName.value;
    originalMemberIds.assignAll(memberIds);
    isEditingGroup.value = true;
    fetchStudentsInSection();
  }

  bool get hasGroupChanges {
    if (!isEditingGroup.value) return false;
    if (groupName.value.trim() != originalGroupName.value.trim()) return true;
    final current = [...selectedStudentIds]..sort();
    final original = [...originalMemberIds]..sort();
    if (current.length != original.length) return true;
    for (int i = 0; i < current.length; i++) {
      if (current[i] != original[i]) return true;
    }
    return false;
  }

  bool get showGroupTab => assignmentInfo.value?.isGroup == true;

  // ================= SUBMISSION =================

  Future<void> _loadExistingSubmissionFiles(int submissionId) async {
    try {
      final result = await submissionRepo.getSubmission(submissionId: submissionId);
      if (result == null) return;
      final attachments = result['attachments'] as List<dynamic>? ?? [];
      if (attachments.isNotEmpty) {
        uploadedFiles.assignAll(attachments.map((a) => <String, dynamic>{
          'original_name': a['original_name'] ?? 'unknown',
          'file_type': a['file_type'] ?? '',
          'file_url': a['file_url'] ?? '',
          'file_size': 0,
          'is_uploading': false,
        }).toList());
        appLog.info('Loaded ${attachments.length} existing files');
      }
    } catch (e) {
      appLog.info('Error loading existing submission files: $e');
    }
  }

  Future<void> pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.any);
      if (result == null || result.files.isEmpty) return;

      for (final file in result.files) {
        if (file.path == null) continue;
        final fileName = file.name;
        final fileType = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
        final fileEntry = <String, dynamic>{
          'original_name': fileName,
          'file_type': fileType,
          'file_size': file.size,
          'file_url': '',
          'is_uploading': true,
          'local_path': file.path,
        };
        uploadedFiles.add(fileEntry);
        final index = uploadedFiles.length - 1;

        try {
          final uploadResult = await submissionRepo.uploadSubmissionFile(
            filePath: file.path!,
            fileName: fileName,
          );
          if (uploadResult != null && uploadResult['file_url'] != null) {
            uploadedFiles[index] = {...fileEntry, 'file_url': uploadResult['file_url'], 'is_uploading': false};
            uploadedFiles.refresh();
          } else {
            uploadedFiles.removeAt(index);
            DialogHelper.showNotification(title: 'อัพโหลดไม่สำเร็จ', message: 'ไม่สามารถอัพโหลดไฟล์ $fileName ได้', type: NotificationType.error);
          }
        } catch (e) {
          if (index < uploadedFiles.length) uploadedFiles.removeAt(index);
        }
      }
    } catch (e) {
      appLog.info('FilePicker error: $e');
    }
  }

  Future<void> removeFile(int index) async {
    if (index < 0 || index >= uploadedFiles.length) return;
    final file = uploadedFiles[index];
    final fileUrl = file['file_url'] as String? ?? '';
    uploadedFiles.removeAt(index);
    if (fileUrl.isNotEmpty) {
      try { await submissionRepo.deleteBlob(fileUrl: fileUrl); }
      catch (e) { appLog.info('Blob delete error (non-critical): $e'); }
    }
  }

  Future<void> submitWork() async {
    if (uploadedFiles.isEmpty) return;
    if (uploadedFiles.any((f) => f['is_uploading'] == true)) {
      DialogHelper.showNotification(title: 'กรุณารอสักครู่', message: 'ไฟล์บางไฟล์ยังอัพโหลดไม่เสร็จ', type: NotificationType.warning);
      return;
    }
    final groupId = group.value?.groupId;
    final assignmentId = assignmentInfo.value?.assignmentId;
    final isGroupAssignment = assignmentInfo.value?.isGroup == true;

    if (assignmentId == null) {
      DialogHelper.showNotification(title: 'เกิดข้อผิดพลาด', message: 'ไม่พบข้อมูล assignment', type: NotificationType.error);
      return;
    }
    if (isGroupAssignment && groupId == null) {
      DialogHelper.showNotification(title: 'ยังไม่มีกลุ่ม', message: 'กรุณาสร้างกลุ่มก่อนส่งงาน', type: NotificationType.error);
      return;
    }

    try {
      isSubmittingWork.value = true;
      final files = uploadedFiles
          .where((f) => (f['file_url'] as String?)?.isNotEmpty == true)
          .map((f) => {'file_url': f['file_url'] as String, 'original_name': f['original_name'] as String, 'file_type': f['file_type'] as String})
          .toList();

      Map<String, dynamic>? result;
      if (existingSubmission.value != null) {
        final submissionId = _parseInt(existingSubmission.value!['submission_id']);
        if (submissionId == null) throw Exception('Invalid submission_id');
        result = await submissionRepo.updateSubmission(submissionId: submissionId, assignmentId: assignmentId, groupId: groupId, files: files);
      } else {
        result = await submissionRepo.createSubmission(assignmentId: assignmentId, groupId: groupId, files: files);
      }

      if (result != null && result['success'] == true) {
        existingSubmission.value = result['data'] as Map<String, dynamic>?;
        if (group.value == null) await fetchGroup();
        DialogHelper.showNotification(title: 'สำเร็จ!', message: 'ส่งงานเรียบร้อยแล้ว', type: NotificationType.success);
        appLog.info('Submission successful');
      } else {
        DialogHelper.showNotification(title: 'ส่งงานไม่สำเร็จ', message: result?['message'] ?? 'ไม่สามารถส่งงานได้', type: NotificationType.error);
      }
    } catch (e) {
      appLog.info('submitWork error: $e');
      String msg = 'ไม่สามารถส่งงานได้';
      final s = e.toString();
      if (s.contains('already exists')) msg = 'คุณส่งงานนี้แล้ว กรุณาลองใหม่อีกครั้ง';
      else if (s.contains('not a member')) msg = 'คุณไม่ได้เป็นสมาชิกของกลุ่มนี้';
      else if (s.contains('not found')) msg = 'ไม่พบข้อมูล assignment หรือ submission';
      else if (s.contains('due date')) msg = 'เลยกำหนดส่งงานแล้ว ไม่สามารถส่งได้';
      DialogHelper.showNotification(title: 'เกิดข้อผิดพลาด', message: msg, type: NotificationType.error);
    } finally {
      isSubmittingWork.value = false;
    }
  }
}