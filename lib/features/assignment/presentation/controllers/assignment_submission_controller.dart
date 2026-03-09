import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/assignment_repository.dart';
import '../../data/repositories/submission_repository.dart';
import '../../data/models/group_model.dart';
import '../../data/models/submission_model.dart';
import '../../data/models/assignment_submission_info.dart';
import 'class_assignment_controller.dart';
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
  final sheetExtent = 0.55.obs;
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
  final isEditingSubmission = false.obs;
  final groupName = ''.obs;

  final uploadedFiles = <Map<String, dynamic>>[].obs;

  // Subject name for display
  final subjectNameTh = RxnString();
  final ImagePicker _imagePicker = ImagePicker();
  int _localUploadSeed = 0;

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

  bool get canModifySubmissionFiles =>
      submission.value == null || isEditingSubmission.value;

  bool get hasUploadingFiles =>
      uploadedFiles.any((f) => f['is_uploading'] == true);

  // ================= INIT =================

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;

    if (args != null) {
      if (args['subjectNameTh'] != null) {
        subjectNameTh.value = args['subjectNameTh'] as String;
      }
      if (args['postId'] != null) {
        fetchAssignment(args['postId']);
      }
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
      isEditingSubmission.value = false;

      appLog.info(
        '📋 Submission: ${result.submission != null ? 'exists (id=${result.submission!.submissionId})' : 'null'}',
      );
      appLog.info(
        '📎 Submission attachments count: ${result.submission?.attachments.length ?? 0}',
      );
      appLog.info(
        '📎 Submission attachments raw: ${result.submission?.attachments}',
      );

      // Populate uploadedFiles from existing submission attachments
      if (result.submission != null &&
          result.submission!.attachments.isNotEmpty) {
        _hydrateUploadedFilesFromSubmission(result.submission!);
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

  void _hydrateUploadedFilesFromSubmission(SubmissionModel submissionModel) {
    uploadedFiles.assignAll(
      submissionModel.attachments.map<Map<String, dynamic>>((att) {
        final fileUrl = att['file_url']?.toString() ?? '';
        final fileType = (att['file_type']?.toString() ?? '').toLowerCase();
        return {
          'file_url': fileUrl,
          'original_name': att['original_name'] ?? fileUrl,
          'file_type': fileType,
          'file_size': att['file_size'] ?? 0,
          'is_uploading': false,
          'is_link': fileType == 'link',
        };
      }).toList(),
    );
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
      final roleOk = s.roleName.toLowerCase().contains('student');
      final active = (s.userStatus ?? '').toLowerCase() == 'active';
      return roleOk && active;
    }).toList();

    appLog.info(
      '👥 _loadStudents: got ${list.length} students, ${activeList.length} active',
    );
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
    appLog.info(
      '🔄 toggleStudent: userId=$userId, currently selected=${selectedStudentIds.toList()}',
    );
    if (selectedStudentIds.contains(userId)) {
      selectedStudentIds.remove(userId);
    } else {
      selectedStudentIds.add(userId);
    }
    appLog.info(
      '🔄 toggleStudent: after toggle, selected=${selectedStudentIds.toList()}',
    );
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

      final userId = authController.userId.value;
      if (userId == null) return;

      final members = {...selectedStudentIds, userId}.whereType<int>().toList();

      bool success;

      if (group.value != null) {
        final groupId = group.value?.groupId;
        if (groupId == null) return;

        success = await repo.updateGroup(
          assignmentId: assignmentId,
          groupId: groupId,
          groupName: groupName.value,
          memberIds: members,
        );
      } else {
        success = await repo.createGroup(
          assignmentId: assignmentId,
          groupName: groupName.value,
          memberIds: members,
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

  void startEditingSubmission() {
    if (submission.value == null) return;
    isEditingSubmission.value = true;

    if (uploadedFiles.isEmpty) {
      _hydrateUploadedFilesFromSubmission(submission.value!);
    }
  }

  void cancelEditingSubmission() {
    isEditingSubmission.value = false;
    if (submission.value != null) {
      _hydrateUploadedFilesFromSubmission(submission.value!);
    }
  }
  // ================= FILE =================

  Future<void> pickFiles({
    FileType fileType = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    if (!canModifySubmissionFiles) return;

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: fileType,
      allowedExtensions: allowedExtensions,
    );

    if (result == null) return;

    for (final file in result.files) {
      if (file.path == null) continue;
      await _uploadLocalFile(
        filePath: file.path!,
        fileName: file.name,
        fileSize: file.size,
        fileType: file.extension ?? '',
      );
    }
  }

  Future<void> _uploadLocalFile({
    required String filePath,
    required String fileName,
    required int fileSize,
    required String fileType,
  }) async {
    final localId = ++_localUploadSeed;
    final entry = {
      'local_id': localId,
      'original_name': fileName,
      'file_type': fileType,
      'file_size': fileSize,
      'file_url': '',
      'is_uploading': true,
    };

    uploadedFiles.add(entry);

    final uploadResult = await submissionRepo.uploadSubmissionFile(
      filePath: filePath,
      fileName: fileName,
    );

    final index = uploadedFiles.indexWhere((f) => f['local_id'] == localId);
    if (index < 0) {
      // User may remove file while uploading; ignore stale upload result.
      return;
    }

    if (uploadResult != null) {
      uploadedFiles[index] = {
        ...entry,
        'file_url': uploadResult['file_url'],
        'is_uploading': false,
      };
      uploadedFiles.refresh();
    } else {
      uploadedFiles.removeAt(index);
    }
  }

  Future<void> pickImageFiles() async {
    if (!canModifySubmissionFiles) return;

    final images = await _imagePicker.pickMultiImage(imageQuality: 95);
    if (images.isEmpty) return;

    for (final image in images) {
      final name = image.name;
      final extIndex = name.lastIndexOf('.');
      final ext = extIndex >= 0 ? name.substring(extIndex + 1) : 'jpg';
      await _uploadLocalFile(
        filePath: image.path,
        fileName: name,
        fileSize: await image.length(),
        fileType: ext,
      );
    }
  }

  void addLinkAttachment(String link) {
    if (!canModifySubmissionFiles) return;

    final trimmed = link.trim();
    final uri = Uri.tryParse(trimmed);
    if (trimmed.isEmpty || uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return;
    }

    uploadedFiles.add({
      'original_name': trimmed,
      'file_type': 'link',
      'file_size': 0,
      'file_url': trimmed,
      'is_uploading': false,
      'is_link': true,
    });
  }

  Future<void> removeFile(int index) async {
    if (!canModifySubmissionFiles) return;
    if (index < 0 || index >= uploadedFiles.length) return;
    if (uploadedFiles[index]['is_uploading'] == true) {
      uploadedFiles.removeAt(index);
      return;
    }
    final fileUrl = uploadedFiles[index]['file_url'];
    final isLink = uploadedFiles[index]['is_link'] == true;
    uploadedFiles.removeAt(index);

    if (!isLink && fileUrl != null && fileUrl.isNotEmpty) {
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
        // Some backend routes may return submission without attachments.
        // Keep current uploaded files in UI to avoid losing visible submitted files.
        final fallbackAttachments = uploadedFiles
            .where((f) => f['file_url'] != null && f['file_url'] != '')
            .map<Map<String, dynamic>>(
              (f) => {
                'file_url': f['file_url'],
                'original_name': f['original_name'],
                'file_type': f['file_type'],
                if (f['file_size'] != null) 'file_size': f['file_size'],
              },
            )
            .toList();

        final resolvedAttachments = result.attachments.isNotEmpty
            ? result.attachments
            : fallbackAttachments;

        submission.value = SubmissionModel(
          submissionId: result.submissionId,
          assignmentId: result.assignmentId,
          groupId: result.groupId,
          groupName: result.groupName,
          submittedAt: result.submittedAt,
          markedAt: result.markedAt,
          score: result.score,
          feedback: result.feedback,
          attachments: resolvedAttachments,
          isGroup: result.isGroup,
        );

        uploadedFiles.assignAll(
          resolvedAttachments.map<Map<String, dynamic>>((att) {
            final fileType = (att['file_type'] ?? '').toString().toLowerCase();
            return {
              'file_url': att['file_url'] ?? '',
              'original_name': att['original_name'] ?? 'unknown',
              'file_type': fileType,
              'file_size': att['file_size'] ?? 0,
              'is_uploading': false,
              'is_link': fileType == 'link',
            };
          }).toList(),
        );

        isEditingSubmission.value = false;

        DialogHelper.showNotification(
          title: 'สำเร็จ',
          message: 'ส่งงานเรียบร้อยแล้ว',
          type: NotificationType.success,
        );

        if (Get.isRegistered<ClassAssignmentController>()) {
          Get.find<ClassAssignmentController>().refreshAssignments();
        }
      }
    } finally {
      isSubmittingWork.value = false;
    }
  }
}
