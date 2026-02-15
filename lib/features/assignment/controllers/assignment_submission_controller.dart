import 'package:get/get.dart';
import '../../../data/repository/assignment_repository.dart';
import '../../../data/model/post_model.dart';
import '../../../data/model/submission_model.dart';
import '../../../core/utils/logger.dart';
import '../../../data/model/assignment_submission_info.dart';
import '../../../core/utils/dialog_helper.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../auth/controller/auth_controller.dart'; // ✅ เพิ่ม import

class AssignmentSubmissionController extends GetxController {
  final AssignmentRepository repo = Get.find();
  final AuthController authController = Get.find(); // ✅ เพิ่มบรรทัดนี้

  final isLoading = true.obs;

  final post = Rxn<PostModel>();
  final submission = Rxn<SubmissionModel>();
  final assignmentInfo = Rxn<AssignmentSubmissionInfo>();
  final group = Rxn<Map<String, dynamic>>();
  final RxInt currentTab = 0.obs;

  // ===== students =====
  final students = <Map<String, dynamic>>[].obs;
  final filteredStudents = <Map<String, dynamic>>[].obs;

   // ===== ✅ เพิ่ม: all groups สำหรับ Teacher
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

  // ✅ ดึง userId จาก AuthController
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

      AppLogger.info('✅ isGroup = ${assignmentInfo.value!.isGroup}');

      if (assignmentInfo.value!.isGroup) {
        // ✅ Teacher: ดึงกลุ่มทั้งหมด
        if (isTeacher) {
          await fetchAllGroups();
        } else {
          // ✅ Student: ดึงกลุ่มของตัวเอง
          await fetchGroup();

          if (group.value == null && currentUserId != null) {
            selectedStudentIds.add(currentUserId!);
            AppLogger.info('✅ Auto-selected current user: $currentUserId');
          }

          await fetchStudentsInSection();
        }
      }
    } finally {
      isLoading.value = false;
    }
  }
// ✅ เพิ่ม: Fetch all groups สำหรับ Teacher
  Future<void> fetchAllGroups() async {
    final assignmentId = assignmentInfo.value?.assignmentId;
    AppLogger.info('🔍 fetchAllGroups assignmentId = $assignmentId');

    if (assignmentId == null) return;

    try {
      isLoadingGroups.value = true;

      final result = await repo.getAllGroups(assignmentId: assignmentId);
      
      AppLogger.info('📦 Fetched ${result.length} groups');
      
      allGroups.assignAll(result);
    } finally {
      isLoadingGroups.value = false;
    }
  }

  
// ✅ เพิ่ม method reset state ทั้งหมด
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
  allGroups.clear(); // ✅ เพิ่ม

  
  // Reset original state
  originalGroupName.value = '';
  originalMemberIds.clear();
  
  // Reset loading
  isStudentLoading.value = false;
  isSubmittingGroup.value = false;
  
  isLoadingGroups.value = false; // ✅ เพิ่ม



}

Future<void> fetchGroup() async {
  final assignmentId = assignmentInfo.value?.assignmentId;
  AppLogger.info('🔍 fetchGroup assignmentId = $assignmentId');

    if (assignmentId == null) return;

    final result = await repo.getGroup(assignmentId: assignmentId);
    AppLogger.info('🔍 getGroup result = $result');

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

  // ✅ ตรวจสอบว่าตัวเองยังอยู่ใน selected หรือไม่
  ensureCurrentUserIsSelected();

  AppLogger.info('🔍 filteredStudents = ${filteredStudents.length}');
}

// ================= SELECT =================

void toggleStudent(int userId) {
  // ✅ ไม่ต้อง check isCurrentUser แล้ว เพราะ UI ไม่ให้กดอยู่แล้ว
  if (selectedStudentIds.contains(userId)) {
    selectedStudentIds.remove(userId);
  } else {
    selectedStudentIds.add(userId);
  }

  selectedStudentIds.refresh();

  AppLogger.info('✅ Selected IDs: $selectedStudentIds');
}

// ✅ ช่วยตรวจสอบว่า selectedStudentIds มีตัวเองอยู่เสมอ
void ensureCurrentUserIsSelected() {
  if (currentUserId != null && !selectedStudentIds.contains(currentUserId)) {
    selectedStudentIds.insert(0, currentUserId!); // เพิ่มไว้ตำแหน่งแรก
    selectedStudentIds.refresh();
    AppLogger.info('🔒 Auto-added current user to selection');
  }
}


  bool isStudentSelected(int userId) {
    return selectedStudentIds.contains(userId);
  }

  // ✅ เช็คว่าเป็นตัวเองหรือไม่
  bool isCurrentUser(int userId) {
    return userId == currentUserId;
  }

  // ================= SUBMIT =================

  bool get canSubmitGroup {
    // ✅ ต้องมีตัวเองอยู่ใน selectedStudentIds
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
    
    // ✅ reset แล้ว auto-select ตัวเองใหม่
    if (currentUserId != null) {
      selectedStudentIds.add(currentUserId!);
    }
    
    originalGroupName.value = '';
    originalMemberIds.clear();
  }

  Future<void> submitGroup() async {
    if (!canSubmitGroup) {
      AppLogger.info('❌ Cannot submit - validation failed');
      return;
    }

    // ✅ Double-check ว่ามีตัวเองอยู่
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
          AppLogger.info('❌ Invalid group_id: $rawGroupId');
          throw Exception('Invalid group_id format');
        }

        AppLogger.info('📤 Updating group: groupId=$groupId, assignmentId=$assignmentId');

        result = await repo.updateGroup(
          assignmentId: assignmentId,
          groupId: groupId,
          groupName: groupName.value.trim(),
          memberIds: selectedStudentIds.toList(),
        );

        AppLogger.info('📥 Update result: $result');
      } else {
        AppLogger.info('📤 Creating group: assignmentId=$assignmentId');
        
        result = await repo.createGroup(
          assignmentId: assignmentId,
          groupName: groupName.value.trim(),
          memberIds: selectedStudentIds.toList(),
        );

        AppLogger.info('📥 Create result: $result');
      }

      if (result != null && result['success'] == true) {
        AppLogger.info('✅ Success! Showing notification');
        
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
      } else {
        AppLogger.info('❌ Result is null or success=false');
        
        DialogHelper.showNotification(
          title: 'ไม่สำเร็จ',
          message: result?['message'] ?? 'ไม่สามารถบันทึกกลุ่มได้',
          type: NotificationType.error,
        );
      }
    } catch (e, stackTrace) {
      AppLogger.info('❌ submitGroup error: $e\n$stackTrace');

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