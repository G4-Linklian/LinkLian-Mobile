import 'package:LinkLian/core/utils/logger.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../shared/models/post_model.dart';
import '../../../shared/repositories/post_repository.dart';
import '../../../auth/controller/auth_controller.dart';
import '../../../../core/services/api_client.dart';
import 'class_feed_controller.dart';

enum CreatePostSource {
  classFeed,
  assignmentFeed,
  classDetail,
  classAssignment,
}

enum CreatePostMode { create, edit }

enum ClosePostAction {
  closeImmediately,
  confirmDiscardEdit,
  confirmDiscardCreate,
}

class CreatePostController extends GetxController {
  final PostRepository postRepository;
  final ApiClient apiClient = ApiClient();
  final Rx<CreatePostMode> mode = CreatePostMode.create.obs;
  int? editingPostContentId;
  late final AuthController auth;
  late final ClassFeedController classFeedController;
  final RxBool isPostTypeLocked = false.obs;
  final RxBool isUploading = false.obs;
  bool _isSubmittingMutex = false;
  final RxBool hasSubmittedStudents = false.obs;
  final RxBool isCheckingSubmissionStatus = false.obs;
  int? editingAssignmentId;

  CreatePostSource source = CreatePostSource.classFeed;

  int? fromSectionId;

  bool get isAllSelected => selectedSectionIds.isEmpty;

  CreatePostController({required this.postRepository});

  final title = ''.obs;
  final content = ''.obs;
  final RxBool isAnonymous = false.obs;
  final RxString postType = ''.obs;
  final RxList<Map<String, dynamic>> attachments = <Map<String, dynamic>>[].obs;
  final RxList<int> selectedSectionIds = <int>[].obs;

  // Assignment-specific fields
  final Rx<DateTime?> dueDate = Rx<DateTime?>(null);
  final RxDouble maxScore = 100.0.obs;
  final RxBool isGroup = false.obs;
  final RxList<Map<String, dynamic>> groups = <Map<String, dynamic>>[].obs;

  final RxBool isLoading = false.obs;
  final isSectionLocked = false.obs;
  final RxList<String> uploadWarnings = <String>[].obs;

  List<int> get effectiveSectionIds {
    if (selectedSectionIds.isEmpty) {
      return classFeedController.classList.map((c) => c.sectionId).toList();
    }
    return selectedSectionIds;
  }

  ClosePostAction get closeAction {
    if (mode.value == CreatePostMode.edit) {
      if (!hasChanges) {
        return ClosePostAction.closeImmediately;
      }
      return ClosePostAction.confirmDiscardEdit;
    }

    if (hasContent) {
      return ClosePostAction.confirmDiscardCreate;
    }

    return ClosePostAction.closeImmediately;
  }

  bool get hasContent {
    return title.value.trim().isNotEmpty ||
        content.value.trim().isNotEmpty ||
        attachments.isNotEmpty;
  }

  bool get hasChanges {
    if (mode.value != CreatePostMode.edit) return false;

    return _originalTitle != title.value ||
        _originalContent != content.value ||
        _hasAttachmentChanges ||
        _hasAssignmentChanges;
  }

  String _originalTitle = '';
  String _originalContent = '';
  List<Map<String, dynamic>> _originalAttachments = [];
  DateTime? _originalDueDate;
  double _originalMaxScore = 100;
  bool _originalIsGroup = false;

  bool get _hasAttachmentChanges {
    if (attachments.length != _originalAttachments.length) return true;

    for (int i = 0; i < attachments.length; i++) {
      if (attachments[i]['file_url'] != _originalAttachments[i]['file_url']) {
        return true;
      }
    }
    return false;
  }

  bool get _hasAssignmentChanges {
    if (postType.value != 'assignment') return false;

    return dueDate.value != _originalDueDate ||
        maxScore.value != _originalMaxScore ||
        isGroup.value != _originalIsGroup;
  }

  bool get canChangeAssignmentType {
    if (mode.value != CreatePostMode.edit) return true;
    if (postType.value != 'assignment') return true;
    return !hasSubmittedStudents.value;
  }

  String get assignmentTypeLockReason =>
      'ไม่สามารถเปลี่ยนประเภทงานได้ เนื่องจากมีนักเรียนส่งงานแล้ว';

  @override
  void onInit() {
    super.onInit();

    try {
      auth = Get.find<AuthController>();
      classFeedController = Get.find<ClassFeedController>();

      // ===== DEFAULT POST TYPE =====
      if (auth.roleName.value == 'teacher' ||
          auth.roleName.value == 'instructor') {
        postType.value = 'announcement';
      } else {
        postType.value = 'question';
      }
    } catch (e) {
      Get.snackbar('เกิดข้อผิดพลาด', 'ไม่สามารถเริ่มต้นแอปพลิเคชัน');
      return;
    }

    final args = Get.arguments as Map<String, dynamic>?;

    // ===== SET SOURCE (DEFAULT TO CLASS FEED) =====
    source = CreatePostSource.classFeed;

    if (args == null) {
      appLog.info('No arguments, using default source: classFeed');
      return;
    }

    if (args['postType'] != null) {
      postType.value = args['postType'] as String;
      appLog.info(
        '[Create Post Controller] Post type from args',
        data: {'postType': postType.value},
      );
    }

    if (args['lockPostType'] == true) {
      isPostTypeLocked.value = true;
      appLog.info('[Create Post Controller] Post type locked');
    }
    // Override source if provided in arguments
    if (args['source'] != null) {
      source = args['source'] as CreatePostSource;
      appLog.info(
        '[Create Post Controller] Source from args',
        data: {'source': source},
      );
    }

    fromSectionId = args['sectionId'] as int?;
    appLog.info(
      '[Create Post Controller] fromSectionId',
      data: {'fromSectionId': fromSectionId},
    );

    // CREATE MODE
    final presetIds = args['presetSectionIds'];
    if (presetIds is List) {
      final validIds = presetIds.whereType<int>().toList();
      if (validIds.isNotEmpty) {
        selectedSectionIds.assignAll(validIds);
      }
    }

    if (args['lockSection'] == true) {
      isSectionLocked.value = true;
      appLog.info('[Create Post Controller] Section locked');
    }

    // EDIT MODE
    if (args['mode'] == CreatePostMode.edit && args['post'] != null) {
      final post = args['post'] as PostModel;

      mode.value = CreatePostMode.edit;
      editingPostContentId = post.postContentId;

      title.value = post.title;
      content.value = post.content;
      postType.value = post.postType;
      isAnonymous.value = post.isAnonymous;

      _originalTitle = post.title;
      _originalContent = post.content;

      // Assignment-specific fields
      if (post.postType == 'assignment') {
        dueDate.value = post.dueDate;
        maxScore.value = post.maxScore ?? 100.0;
        isGroup.value = post.isGroup ?? false;

        // Store original assignment values
        _originalDueDate = post.dueDate;
        _originalMaxScore = post.maxScore ?? 100.0;
        _originalIsGroup = post.isGroup ?? false;

        _checkSubmittedStudentsForEditing(post.postId);
      }

      attachments.assignAll(
        post.attachments?.map((a) {
              return {
                'file_url': a.fileUrl,
                'file_type': a.fileType,
                'original_name': a.originalName ?? a.fileName ?? 'ไฟล์แนบ',
                'file_name': a.originalName ?? a.fileName ?? 'ไฟล์แนบ',
                'file_blob_name': a.fileBlobName,
                'file_size': a.fileSize ?? 0,
              };
            }).toList() ??
            [],
      );

      // Store original attachments
      _originalAttachments = List.from(attachments);

      // Fetch file sizes from blob if not available
      _fetchFileSizesFromBlob();

      if (args['sectionId'] != null) {
        selectedSectionIds.assignAll([args['sectionId'] as int]);
        isSectionLocked.value = true;
      }

      appLog.info('[Create Post Controller] Edit mode initialized');
    }
  }

  /// UPLOAD FILE (Strict Mode)
  Future<bool> uploadFiles(List<File> files) async {
    uploadWarnings.clear();
    isUploading.value = true;

    try {
      final uploadedFiles = await postRepository.uploadAttachments(
        files: files,
      );

      if (uploadedFiles.isEmpty) return false;

      for (int i = 0; i < files.length; i++) {
        if (i >= uploadedFiles.length) continue;

        final localFile = files[i];
        final serverFile = uploadedFiles[i];

        final originalName = localFile.path.split('/').last;

        attachments.add({
          'file_url': serverFile['fileUrl'] ?? serverFile['file_url'],
          'file_type': serverFile['fileType'] ?? serverFile['file_type'],
          'file_blob_name': serverFile['fileName'] ?? serverFile['file_name'],
          'file_name': originalName,
          'original_name': originalName,
          'file_size': await localFile.length(),
        });
      }

      return true;
    } catch (e) {
      return false;
    } finally {
      isUploading.value = false;
    }
  }

  /// REMOVE ATTACHMENT
  Future<void> removeAttachment(int index) async {
    if (index < 0 || index >= attachments.length) return;

    final file = attachments[index];
    final isLink = file['file_type'] == 'link';

    if (!isLink && file['file_blob_name'] != null) {
      try {
        await postRepository.deleteAttachmentBlob(file['file_blob_name']);
      } catch (_) {}
    }

    attachments.removeAt(index);
  }

  /// FETCH FILE SIZES FROM BLOB (for edit mode)
  Future<void> _fetchFileSizesFromBlob() async {
    try {
      appLog.info('📏 Fetching file sizes from blob...');

      for (int i = 0; i < attachments.length; i++) {
        final attachment = attachments[i];
        final fileUrl = attachment['file_url'] as String?;

        if (fileUrl == null || fileUrl.isEmpty) continue;
        if (attachment['file_size'] != null && attachment['file_size'] > 0)
          continue;

        try {
          final response = await http.head(Uri.parse(fileUrl));

          if (response.statusCode == 200) {
            final contentLength = response.headers['content-length'];
            if (contentLength != null) {
              final fileSize = int.tryParse(contentLength) ?? 0;

              attachments[i] = {...attachment, 'file_size': fileSize};

              appLog.info(
                '[Create Post Controller] File size fetched',
                data: {
                  'fileName': attachment['file_name'],
                  'fileSize': fileSize,
                },
              );
            }
          }
        } catch (e) {
          appLog.info(
            '[Create Post Controller] Failed to fetch size',
            data: {'fileName': attachment['file_name']},
          );
        }
      }

      appLog.info('[Create Post Controller] File sizes fetched successfully');
    } catch (e) {
      appLog.info('[Create Post Controller] Error fetching file sizes: $e');
    }
  }

  Future<Map<String, dynamic>> submitPost() async {
    if (_isSubmittingMutex || isLoading.value) {
      return {
        'success': false,
        'ignored': true,
        'message': 'กำลังโพสต์อยู่ กรุณารอสักครู่',
      };
    }

    try {
      _isSubmittingMutex = true;
      isLoading.value = true;
      appLog.info(
        '[Create Post Controller] Submitting post',
        data: {'mode': mode.value},
      );

      Map<String, dynamic> result;
      if (mode.value == CreatePostMode.edit) {
        result = await _updatePost();
      } else {
        result = await _createPost();
      }

      appLog.info('[Create Post Controller] Submit result: $result');
      return result;
    } catch (e) {
      appLog.info('[Create Post Controller] Submit error: $e');
      rethrow;
    } finally {
      _isSubmittingMutex = false;
      isLoading.value = false;
    }
  }

Future<Map<String, dynamic>> _createPost() async {
  final post = await postRepository.createPost(
    sectionIds: effectiveSectionIds,
    title: title.value.trim(),
    content: content.value,
    postType: postType.value,
    isAnonymous: isAnonymous.value,
    attachments: attachments,
    dueDate: dueDate.value?.toIso8601String(),
    maxScore: maxScore.value,
    isGroup: isGroup.value,
    groups: groups.toList(),
  );

  if (post == null) {
    return {
      'success': false,
      'message': 'Create post failed',
    };
  }

  return {
    'success': true,
    'data': post,
  };
}

Future<Map<String, dynamic>> _updatePost() async {
  try {
    final isTeacher =
        auth.roleName.value == 'teacher' ||
        auth.roleName.value == 'instructor';

      if (isTeacher &&
          postType.value == 'assignment' &&
          hasSubmittedStudents.value &&
          isGroup.value != _originalIsGroup) {
        return {'success': false, 'message': assignmentTypeLockReason};
      }

      final success = await postRepository.updatePost(
  postContentId: editingPostContentId!,
  title: title.value,
  content: content.value,
  attachments: attachments.toList(),
  dueDate: dueDate.value?.toIso8601String(),
  maxScore: maxScore.value,
  isGroup: isGroup.value,
  groups: groups.toList(),
);

return {
  'success': true,
};
    } catch (e) {
      rethrow;
    }
  }

  void setAssignmentIsGroup(bool value) {
    if (!canChangeAssignmentType) return;
    if (isGroup.value == value) return;
    isGroup.value = value;
    // Reset local group draft when switching type.
    groups.clear();
  }

  Future<void> _checkSubmittedStudentsForEditing(int postId) async {
    isCheckingSubmissionStatus.value = true;
    try {
      final assignmentRes = await apiClient.get<Map<String, dynamic>>(
        '/assignment/post',
        queryParameters: {
          'post_id': postId,
          'role': auth.roleName.value ?? 'teacher',
        },
      );

      final assignmentId = _extractAssignmentId(assignmentRes.data);
      editingAssignmentId = assignmentId;
      if (assignmentId == null) {
        hasSubmittedStudents.value = false;
        return;
      }

      final statusRes = await apiClient.get<Map<String, dynamic>>(
        '/assignment/submission/students/$assignmentId',
      );

      final data = statusRes.data?['data'];
      if (data is! List) {
        hasSubmittedStudents.value = false;
        return;
      }

      hasSubmittedStudents.value = data.any((e) {
        if (e is! Map) return false;
        final raw = Map<String, dynamic>.from(e);
        final sid = _toNullableInt(raw['submission_id']);
        if (sid != null) return true;
        if (raw['submitted_at'] != null) return true;
        final status = (raw['submission_status'] ?? '')
            .toString()
            .toLowerCase();
        return status == 'submitted' ||
            status == 'graded' ||
            status == 'marked';
      });
    } catch (e) {
      appLog.warning(
        '[Create Post Controller] check submitted students failed: $e',
      );
      hasSubmittedStudents.value = false;
    } finally {
      isCheckingSubmissionStatus.value = false;
    }
  }

  int? _extractAssignmentId(Map<String, dynamic>? response) {
    if (response == null) return null;
    final data = response['data'];
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);

    final direct = _toNullableInt(map['assignment_id']);
    if (direct != null) return direct;

    final assignment = map['assignment'];
    if (assignment is Map) {
      final id = _toNullableInt(assignment['assignment_id']);
      if (id != null) return id;
    }

    final post = map['post'];
    if (post is Map) {
      final id = _toNullableInt(post['assignment_id']);
      if (id != null) return id;
    }
    return null;
  }

  int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  void onClose() {
    super.onClose();
  }
}
