import 'package:get/get.dart';
import 'dart:io';
import '../../../data/repository/post_repository.dart';
import '../../auth/controller/auth_controller.dart';
import '../../../core/services/api_client.dart';
import '../controllers/class_feed_controller.dart';
import '../../../core/utils/dialog_helper.dart';
import 'package:dio/dio.dart';
import '../controllers/class_detail_controller.dart';
import '../../../data/model/post_model.dart';

enum CreatePostSource { classFeed, classDetail }

enum CreatePostMode { create, edit }

class CreatePostController extends GetxController {
  final PostRepository postRepository;
  final ApiClient apiClient = ApiClient();
  final Rx<CreatePostMode> mode = CreatePostMode.create.obs;
  int? editingPostContentId;
  late final AuthController auth;
  late final ClassFeedController classFeedController;
  late final CreatePostSource source;

  int? fromSectionId;

  bool get isAllSelected => selectedSectionIds.isEmpty;

  CreatePostController({required this.postRepository});

  final title = ''.obs;
  final content = ''.obs;
  final RxBool isAnonymous = false.obs;
  final RxString postType = ''.obs;
  final RxList<Map<String, dynamic>> attachments = <Map<String, dynamic>>[].obs;
  final RxList<int> selectedSectionIds = <int>[].obs;

  final RxBool isLoading = false.obs;
  final isSectionLocked = false.obs;

  List<int> get effectiveSectionIds {
    if (selectedSectionIds.isEmpty) {
      return classFeedController.classList.map((c) => c.sectionId).toList();
    }
    return selectedSectionIds;
  }

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

    if (args == null) {
      source = CreatePostSource.classFeed;
      return;
    }

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
    }

    // EDIT MODE
    if (args['mode'] == CreatePostMode.edit && args['post'] != null) {
      final post = args['post'] as PostModel;

      mode.value = CreatePostMode.edit;
      editingPostContentId = post.postContentId;

      title.value = post.title;
      content.value = post.content;
      postType.value = post.postType;

      attachments.assignAll(
        post.attachments?.map((a) {
              return {
                'file_url': a.fileUrl,
                'file_type': a.fileType,
                'file_name': a.fileName ?? 'ไฟล์แนบ',
                'file_blob_name': a.fileBlobName,
                'file_size': a.fileSize ?? 0,
              };
            }).toList() ??
            [],
      );

      if (args['sectionId'] != null) {
        selectedSectionIds.assignAll([args['sectionId'] as int]);
        isSectionLocked.value = true;
      }
    }

    // COMMON
    source = args['source'] ?? CreatePostSource.classFeed;
    fromSectionId = args['sectionId'] as int?;
  }

  /// UPLOAD FILE
  Future<void> uploadFiles(List<File> files) async {
    try {
      final res = await apiClient.uploadMultipart(
        '/uploadFile/social-feed/fileattachment',
        files: files,
        fieldName: 'files',
      );

      final uploadedFiles = res.data['files'] as List;

      for (int i = 0; i < uploadedFiles.length; i++) {
        final f = uploadedFiles[i];
        final file = files[i];

        attachments.add({
          'file_url': f['fileUrl'],
          'file_type': f['fileType'],
          'file_name': f['originalName'],
          'file_blob_name': f['fileName'],
          'file_size': await file.length(),
        });
      }
    } catch (e) {
      Get.snackbar('เกิดข้อผิดพลาด', 'ไม่สามารถอัปโหลดไฟล์');
    }
  }

  /// REMOVE ATTACHMENT
  Future<void> removeAttachment(int index) async {
    if (index < 0 || index >= attachments.length) return;

    final file = attachments[index];

    try {
      await apiClient.delete(
        '/deleteFile/social-feed',
        data: {
          'fileNames': [file['file_blob_name']],
        },
      );
    } catch (e) {}

    attachments.removeAt(index);
  }

  Future<Map<String, dynamic>> submitPost() async {
    try {
      isLoading.value = true;

      if (mode.value == CreatePostMode.edit) {
        return await _updatePost();
      }

      return await _createPost();
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> _createPost() async {
    final isTeacher =
        auth.roleName.value == 'teacher' || auth.roleName.value == 'instructor';

    String effectiveTitle;
    if (isTeacher) {
      effectiveTitle = title.value.trim();
    } else {
      effectiveTitle = content.value.trim();
    }

    return postRepository.createPost(
      sectionIds: effectiveSectionIds,
      title: effectiveTitle,
      content: content.value,
      postType: postType.value,
      isAnonymous: isAnonymous.value,
      attachments: attachments,
    );
  }

  Future<Map<String, dynamic>> _updatePost() async {
    try {
      return await postRepository.updatePost(
        postContentId: editingPostContentId!,
        title: title.value,
        content: content.value,
        attachments: attachments,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}
