import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/repositories/assignment_repository.dart';
import '../../data/repositories/submission_repository.dart';
import '../../data/models/group_model.dart';
import '../../data/models/submission_model.dart';
import '../../data/models/assignment_submission_info.dart';
import '../../../auth/controller/auth_controller.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../../../../core/utils/logger.dart';
import '../../../shared/models/profile_model.dart';

class AssignmentSubmissionController extends GetxController {
  final AssignmentRepository repo;
  final SubmissionRepository submissionRepo;
  final AuthController authController;

  AssignmentSubmissionController({
    required this.repo,
    required this.submissionRepo,
    required this.authController,
  });

  // ================= STATE =================

  final isLoading = true.obs;
  final isSubmittingWork = false.obs;
  final isSubmittingGroup = false.obs;
  final isLoadingGroups = false.obs;

  final currentTab = 0.obs;
  final post = Rxn<dynamic>();
  final isStudentLoading = false.obs;

  final submission = Rxn<SubmissionModel>();
  final assignmentInfo = Rxn<AssignmentSubmissionInfo>();

  final group = Rxn<GroupModel>();
  final allGroups = <GroupModel>[].obs;

  final students = <ProfileModel>[].obs;
final filteredStudents = <ProfileModel>[].obs;

  final selectedStudentIds = <int>[].obs;

  final isEditingGroup = false.obs;
  final groupName = ''.obs;

  final uploadedFiles = <Map<String, dynamic>>[].obs;

  // ================= GETTERS =================

  bool get showGroupTab => assignmentInfo.value?.isGroup == true;

  bool get isTeacher {
    final role = authController.roleName.value?.toLowerCase() ?? '';
    return role.contains('teacher') || role.contains('instructor');
  }

  bool get canSubmitGroup =>
      groupName.value.trim().isNotEmpty &&
      selectedStudentIds.isNotEmpty &&
      !isSubmittingGroup.value;

  // ================= INIT =================

  @override
  void onInit() {
    super.onInit();
   final args = Get.arguments as Map<String, dynamic>?;

if (args != null && args['postId'] != null) {
  fetchAssignment(args['postId']);
}
  }

  // ================= FETCH ASSIGNMENT =================

  Future<void> fetchAssignment(int postId) async {
    try {
      isLoading.value = true;

      final result = await repo.getPostAssignment(
        postId: postId,
        role: authController.roleName.value,
      );

      if (result == null) return;

      post.value = result.post;
      assignmentInfo.value = result.assignment;
      submission.value = result.submission;

      appLog.info('📋 Submission: ${result.submission != null ? 'exists (id=${result.submission!.submissionId})' : 'null'}');
      appLog.info('📎 Submission attachments count: ${result.submission?.attachments.length ?? 0}');
      appLog.info('📎 Submission attachments raw: ${result.submission?.attachments}');

      // Populate uploadedFiles from existing submission attachments
      if (result.submission != null && result.submission!.attachments.isNotEmpty) {
        uploadedFiles.assignAll(
          result.submission!.attachments.map<Map<String, dynamic>>((att) {
            final a = att is Map<String, dynamic> ? att : <String, dynamic>{};
            return {
              'file_url': a['file_url'] ?? '',
              'original_name': a['original_name'] ?? 'unknown',
              'file_type': a['file_type'] ?? '',
              'file_size': a['file_size'] ?? 0,
              'is_uploading': false,
            };
          }).toList(),
        );
        appLog.info('📎 Loaded ${uploadedFiles.length} existing attachments');
      } else {
        uploadedFiles.clear();
      }

      if (assignmentInfo.value?.isGroup == true) {
        await _loadStudents();

        if (isTeacher) {
          await _loadAllGroups();
        } else {
          await _loadMyGroup();
        }
      }
    } finally {
      isLoading.value = false;
    }
  }
  // ================= GROUP =================

  Future<void> _loadStudents() async {
    isStudentLoading.value = true;

    final sectionId = post.value?.sectionId;
    if (sectionId == null) {
      appLog.info('⚠️ _loadStudents: sectionId is null');
      isStudentLoading.value = false;
      return;
    }

    appLog.info('📡 _loadStudents: fetching for sectionId=$sectionId');
    final list = await repo.getStudentsInSection(sectionId: sectionId);

    // Filter out inactive users — only show Active students
    final activeList = list.where((s) {
  return s.roleName.toLowerCase().contains('student');
}).toList();

    appLog.info('👥 _loadStudents: got ${list.length} students, ${activeList.length} active');
    for (final s in activeList) {
      appLog.info(
        '  → user_sys_id=${s.userSysId} | '
        '${s.firstName} ${s.lastName} | '
        'status=${s.userStatus ?? 'n/a'}',
      );
    }

    students.assignAll(activeList);
    filteredStudents.assignAll(activeList);

    isStudentLoading.value = false;
  }

  Future<void> _loadMyGroup() async {
    final g = await repo.getGroup(
      assignmentId: assignmentInfo.value!.assignmentId,
    );
    group.value = g;
  }

  Future<void> _loadAllGroups() async {
    isLoadingGroups.value = true;
    final groups = await repo.getAllGroups(
      assignmentId: assignmentInfo.value!.assignmentId,
    );
    allGroups.assignAll(groups);
    isLoadingGroups.value = false;
  }

  void startEditingGroup() {
    isEditingGroup.value = true;
    groupName.value = group.value?.groupName ?? '';

    selectedStudentIds.assignAll(
      group.value?.members.map((e) => e.userSysId).whereType<int>().toList() ??
          [],
    );
  }

  void cancelEditingGroupWithConfirm() {
    isEditingGroup.value = false;
    selectedStudentIds.clear();
  }

  void toggleStudent(int userId) {
    appLog.info('🔄 toggleStudent: userId=$userId, currently selected=${selectedStudentIds.toList()}');
    if (selectedStudentIds.contains(userId)) {
      selectedStudentIds.remove(userId);
    } else {
      selectedStudentIds.add(userId);
    }
    appLog.info('🔄 toggleStudent: after toggle, selected=${selectedStudentIds.toList()}');
  }

  bool isStudentSelected(int userId) {
    return selectedStudentIds.contains(userId);
  }

  bool isCurrentUser(int userId) {
    return authController.userId.value == userId;
  }

  void onSearchChanged(String value) {
    final keyword = value.toLowerCase();
    filteredStudents.assignAll(
      students.where((s) {
        final name = '${s.firstName} ${s.lastName}'.toLowerCase();
        return name.contains(keyword);
      }).toList(),
    );
  }

  Future<void> submitGroup() async {
    try {
      isSubmittingGroup.value = true;

      final assignmentId = assignmentInfo.value?.assignmentId;
      if (assignmentId == null) return;

      bool success;

      if (group.value != null) {
        final groupId = group.value?.groupId;
        if (groupId == null) return; // 🔐 ป้องกัน null

        success = await repo.updateGroup(
          assignmentId: assignmentId,
          groupId: groupId,
          groupName: groupName.value,
          memberIds: selectedStudentIds,
        );
      } else {
        success = await repo.createGroup(
          assignmentId: assignmentId,
          groupName: groupName.value,
          memberIds: selectedStudentIds,
        );
      }

      if (success) {
        await _loadMyGroup();
        isEditingGroup.value = false;
      }
    } finally {
      isSubmittingGroup.value = false;
    }
  }
  // ================= FILE =================

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result == null) return;

    for (final file in result.files) {
      if (file.path == null) continue;

      final entry = {
        'original_name': file.name,
        'file_type': file.extension ?? '',
        'file_size': file.size,
        'file_url': '',
        'is_uploading': true,
      };

      uploadedFiles.add(entry);
      final index = uploadedFiles.length - 1;

      final uploadResult = await submissionRepo.uploadSubmissionFile(
        filePath: file.path!,
        fileName: file.name,
      );

      if (uploadResult != null) {
        uploadedFiles[index] = {
          ...entry,
          'file_url': uploadResult['file_url'],
          'is_uploading': false,
        };
        uploadedFiles.refresh();
      }
    }
  }

  Future<void> removeFile(int index) async {
    if (index < 0 || index >= uploadedFiles.length) return;
    final fileUrl = uploadedFiles[index]['file_url'];
    uploadedFiles.removeAt(index);

    if (fileUrl != null && fileUrl.isNotEmpty) {
      await submissionRepo.deleteBlob(fileUrl: fileUrl);
    }
  }

  // ================= SUBMIT WORK =================
  Future<void> submitWork() async {
    if (uploadedFiles.isEmpty) return;

    try {
      isSubmittingWork.value = true;

      final assignmentId = assignmentInfo.value?.assignmentId;
      if (assignmentId == null) return;

      final files = uploadedFiles
          .where((f) => f['file_url'] != null && f['file_url'] != '')
          .map(
            (f) => {
              'file_url': f['file_url'],
              'original_name': f['original_name'],
              'file_type': f['file_type'],
            },
          )
          .toList();

SubmissionModel? result;
      // If submission already exists → update, otherwise → create
      
if (submission.value != null) {
  result = await submissionRepo.updateSubmission(
    submissionId: submission.value!.submissionId,
    assignmentId: assignmentId,
    groupId: group.value?.groupId,
    files: files,
  );
} else {
  result = await submissionRepo.createSubmission(
    assignmentId: assignmentId,
    groupId: group.value?.groupId,
    files: files,
  );
}

if (result != null) {
  submission.value = result;

  DialogHelper.showNotification(
    title: 'สำเร็จ',
    message: 'ส่งงานเรียบร้อยแล้ว',
    type: NotificationType.success,
  );
}
    } finally {
      isSubmittingWork.value = false;
    }
  }
}
