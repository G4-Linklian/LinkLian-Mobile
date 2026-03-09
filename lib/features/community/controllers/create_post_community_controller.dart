import 'dart:io';
import 'package:LinkLian/core/utils/logger.dart';
import 'package:LinkLian/data/model/community_attachment_model.dart';
import 'package:LinkLian/data/repository/profile_repository.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../data/repository/community_post_repository.dart';

class CreatePostCommunityController extends GetxController {
  final CommunityPostRepository _repo;
  final ProfileRepository _profileRepo;

  CreatePostCommunityController(this._repo, this._profileRepo);

  final contentController = TextEditingController();

  final RxString userProfileImage = ''.obs;
  final RxString userFullName = ''.obs;

  final RxBool isSubmitting = false.obs;

  RxBool isEditMode = false.obs;
  int? editingPostId;

  final RxList<File> selectedFiles = <File>[].obs;

  final RxList<Map<String, dynamic>> filesPreviews =
      <Map<String, dynamic>>[].obs;

  final RxList<CommunityAttachmentModel> existingAttachments =
      <CommunityAttachmentModel>[].obs;
  late int communityId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      communityId = args['community_id'] ?? 0;

      final userId = args['userId'];

      if (userId != null) {
        _loadUserProfile(userId);
      }

      if (args['isEdit'] == true) {
        isEditMode.value = true;
        final post = args['post'];
        editingPostId = post.postId;
        contentController.text = post.content;
        userProfileImage.value = post.profilePic ?? '';
        userFullName.value = "${post.firstName} ${post.lastName}";

        for (var att in post.attachments) {
          existingAttachments.add(att);

          filesPreviews.add({
            'file_type': att.fileType,
            'file_url': att.fileUrl,
            'file_name': att.originalName,
            'is_existing': true,
            'is_uploading': false,
          });
        }
      }
    } else {
      communityId = 0;
    }
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage() async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);

      if (file == null) {
        return;
      }

      final imageFile = File(file.path);
      selectedFiles.add(imageFile);

      final previewIndex = filesPreviews.length;
      filesPreviews.add({
        'file_name': file.name,
        'file_type': 'image',
        'file_path': file.path,
        'file_size': await imageFile.length(),
        'is_uploading': true,
        'upload_progress': 0.0,
      });

      await _simulateUpload(previewIndex);
    } catch (e) {
      DialogHelper.showNotification(
        title: 'เกิดข้อผิดพลาด',
        message: 'ไม่สามารถเลือกรูปภาพได้',
        type: NotificationType.error,
      );
    }
  }

  Future<void> pickImageFromCamera() async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.camera);

      if (file == null) {
        return;
      }

      final imageFile = File(file.path);
      selectedFiles.add(imageFile);

      final previewIndex = filesPreviews.length;
      filesPreviews.add({
        'file_name': file.name,
        'file_type': 'image',
        'file_path': file.path,
        'file_size': await imageFile.length(),
        'is_uploading': true,
        'upload_progress': 0.0,
      });

      await _simulateUpload(previewIndex);
    } catch (e) {
      DialogHelper.showNotification(
        title: 'เกิดข้อผิดพลาด',
        message: 'ไม่สามารถถ่ายรูปได้',
        type: NotificationType.error,
      );
    }
  }

  Future<void> uploadFiles(List<File> files) async {
    try {
      for (final file in files) {
        selectedFiles.add(file);

        final previewIndex = filesPreviews.length;
        filesPreviews.add({
          'file_name': file.path.split('/').last,
          'file_type': _getFileType(file.path),
          'file_path': file.path,
          'file_size': await file.length(),
          'is_uploading': true,
          'upload_progress': 0.0,
        });

        await _simulateUpload(previewIndex);
      }
    } catch (e) {
      appLog.info('[community]Add files error: $e');
    }
  }

  Future<void> _simulateUpload(int index) async {
    if (index < 0 || index >= filesPreviews.length) return;

    for (var progress = 0.0; progress <= 1.0; progress += 0.1) {
      await Future.delayed(const Duration(milliseconds: 200));

      if (index < filesPreviews.length) {
        filesPreviews[index]['upload_progress'] = progress;
        filesPreviews.refresh();
      }
    }

    if (index < filesPreviews.length) {
      filesPreviews[index]['is_uploading'] = false;
      filesPreviews[index]['upload_progress'] = 1.0;
      filesPreviews.refresh();
    }
  }

  void addLink(String url) {
    if (url.trim().isEmpty) {
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      DialogHelper.showNotification(
        title: 'ลิงก์ไม่ถูกต้อง',
        message: 'กรุณาใส่ลิงก์ที่ขึ้นต้นด้วย http:// หรือ https://',
        type: NotificationType.warning,
      );
      return;
    }

    filesPreviews.add({
      'file_type': 'link',
      'file_url': url,
      'file_name': url,
      'file_size': 0,
      'is_uploading': false,
      'upload_progress': 1.0,
    });
  }

  void removeAttachment(int index) {
    if (index < 0 || index >= filesPreviews.length) return;

    final preview = filesPreviews[index];

    if (preview['is_existing'] == true) {
      existingAttachments.removeWhere((e) => e.fileUrl == preview['file_url']);
    } else if (preview['file_type'] != 'link') {
      final filePath = preview['file_path'];
      selectedFiles.removeWhere((file) => file.path == filePath);
    }

    filesPreviews.removeAt(index);
  }

  Future<void> submitPost() async {
    final content = contentController.text.trim();

    final links = filesPreviews
        .where((e) => e['file_type'] == 'link')
        .map((e) => e['file_url'] as String)
        .toList();

    if (content.isEmpty && links.isEmpty) {
      DialogHelper.showNotification(
        title: 'กรุณากรอกข้อความ',
        message: 'โปรดพิมพ์ข้อความหรือแนบลิงก์ก่อนโพสต์',
        type: NotificationType.warning,
      );
      return;
    }

    final fullContent = links.isNotEmpty
        ? "$content\n${links.join("\n")}"
        : content;

    try {
      isSubmitting.value = true;

      if (isEditMode.value && editingPostId != null) {
        final updatedPost = await _repo.updatePost(
          postId: editingPostId!,
          content: fullContent,
          files: selectedFiles.isNotEmpty ? selectedFiles : null,
          keepAttachments: existingAttachments.toList(),
        );

        Get.back(result: updatedPost);
      } else {
        final newPost = await _repo.createPost(
          communityId: communityId,
          content: fullContent,
          files: selectedFiles.isNotEmpty ? selectedFiles : null,
        );

        Get.back(result: newPost);
      }
    } catch (e) {
      DialogHelper.showNotification(
        title: 'เกิดข้อผิดพลาด',
        message: 'ไม่สามารถบันทึกโพสต์ได้\n$e',
        type: NotificationType.error,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);

      if (file == null) return;

      final imageFile = File(file.path);

      selectedFiles.add(imageFile);

      filesPreviews.add({
        'file_name': file.name,
        'file_type': 'image',
        'file_path': file.path,
        'file_size': await imageFile.length(),
      });
    } catch (e) {
      DialogHelper.showNotification(
        title: 'เกิดข้อผิดพลาด',
        message: 'ไม่สามารถเลือกรูปภาพได้',
        type: NotificationType.error,
      );
    }
  }

  Future<void> _loadUserProfile(int userId) async {
    try {
      final profile = await _profileRepo.getProfile(userId);

      userProfileImage.value = profile.profilePic ?? '';
      userFullName.value = "${profile.firstName} ${profile.lastName}";
    } catch (e) {
      appLog.info("[community]Upload file successful: $e");
    }
  }

  String _getFileType(String filePath) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];
    final extension = filePath.split('.').last.toLowerCase();

    if (imageExtensions.contains(extension)) {
      return 'image';
    } else if (extension == 'pdf') {
      return 'pdf';
    } else if (['mp4', 'mov', 'avi'].contains(extension)) {
      return 'video';
    } else {
      return 'file';
    }
  }

  @override
  void onClose() {
    contentController.dispose();
    super.onClose();
  }
}
