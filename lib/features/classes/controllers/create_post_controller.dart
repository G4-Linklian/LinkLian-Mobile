import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../data/repository/post_repository.dart';
import '../../auth/controller/auth_controller.dart';
import '../../../core/services/api_client.dart';
import '../controllers/class_feed_controller.dart';
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
  CreatePostSource source = CreatePostSource.classFeed; // Not late

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
  final RxInt maxScore = 100.obs;
  final RxBool isGroup = false.obs;
  final RxList<Map<String, dynamic>> groups = <Map<String, dynamic>>[].obs;

  final RxBool isLoading = false.obs;
  final isSectionLocked = false.obs;
  final RxList<String> uploadWarnings = <String>[].obs; // เพิ่ม warnings list

  List<int> get effectiveSectionIds {
    if (selectedSectionIds.isEmpty) {
      return classFeedController.classList.map((c) => c.sectionId).toList();
    }
    return selectedSectionIds;
  }

  /// Check if user has entered any content
  bool get hasContent {
    return title.value.trim().isNotEmpty || 
           content.value.trim().isNotEmpty || 
           attachments.isNotEmpty;
  }

  /// Check if there are changes from original (for edit mode)
  bool get hasChanges {
    if (mode.value != CreatePostMode.edit) return false;
    
    // Compare with original values (stored when entering edit mode)
    return _originalTitle != title.value ||
           _originalContent != content.value ||
           _hasAttachmentChanges ||
           _hasAssignmentChanges;
  }

  // Store original values for comparison
  String _originalTitle = '';
  String _originalContent = '';
  List<Map<String, dynamic>> _originalAttachments = [];
  DateTime? _originalDueDate;
  int _originalMaxScore = 100;
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
    source = CreatePostSource.classFeed; // Default

    if (args == null) {
      debugPrint('📝 No arguments, using default source: classFeed');
      return;
    }

    // Override source if provided in arguments
    if (args['source'] != null) {
      source = args['source'] as CreatePostSource;
      debugPrint('📝 Source from args: $source');
    }

    fromSectionId = args['sectionId'] as int?;
    debugPrint('📝 fromSectionId: $fromSectionId');

    // CREATE MODE
    final presetIds = args['presetSectionIds'];
    if (presetIds is List) {
      final validIds = presetIds.whereType<int>().toList();
      if (validIds.isNotEmpty) {
        selectedSectionIds.assignAll(validIds);
        debugPrint('📝 Preset section IDs: $validIds');
      }
    }

    if (args['lockSection'] == true) {
      isSectionLocked.value = true;
      debugPrint('📝 Section locked');
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

      // Store original values for change detection
      _originalTitle = post.title;
      _originalContent = post.content;

      // Assignment-specific fields
      if (post.postType == 'assignment') {
        dueDate.value = post.dueDate;
        maxScore.value = post.maxScore ?? 100;
        isGroup.value = post.isGroup ?? false;
        
        // Store original assignment values
        _originalDueDate = post.dueDate;
        _originalMaxScore = post.maxScore ?? 100;
        _originalIsGroup = post.isGroup ?? false;
      }

      attachments.assignAll(
        post.attachments?.map((a) {
              return {
                'file_url': a.fileUrl,
                'file_type': a.fileType,
                'original_name': a.originalName ?? a.fileName ?? 'ไฟล์แนบ',
                'file_name': a.originalName ?? a.fileName ?? 'ไฟล์แนบ',
                'file_blob_name': a.fileBlobName,
                'file_size': a.fileSize ?? 0, // ใช้ค่าที่มีอยู่ หรือ 0 ถ้าไม่มี
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

      debugPrint('📝 Edit mode initialized');
    }
  }

  /// UPLOAD FILE (Strict Mode)
  Future<bool> uploadFiles(List<File> files) async {
    uploadWarnings.clear(); // Clear previous warnings
    
    try {
      debugPrint('📤 Starting upload... files: ${files.length}');
      
      final res = await apiClient.uploadMultipart(
        '/uploadFile/social-feed/fileattachment',
        files: files,
        fieldName: 'files',
      );

      debugPrint('📤 Upload response: ${res.data}');

      final data = res.data;
      if (data == null) {
        debugPrint('❌ Upload response is null');
        return false;
      }

      // Handle various response formats
      List? uploadedFiles;
      
      if (data is Map) {
        if (data.containsKey('files')) {
          uploadedFiles = data['files'] as List?;
        } else if (data.containsKey('data') && data['data'] is Map) {
          uploadedFiles = data['data']['files'] as List?;
        } else if (data.containsKey('data') && data['data'] is List) {
          uploadedFiles = data['data'] as List?;
        }
      } else if (data is List) {
        uploadedFiles = data;
      }

      if (uploadedFiles == null || uploadedFiles.isEmpty) {
        debugPrint('❌ No files in response');
        return false;
      }

      // Add uploaded files to attachments (strict validation)
      int successCount = 0;
      int failedCount = 0;
      
      for (int i = 0; i < files.length; i++) {
        try {
          if (i >= uploadedFiles.length) {
            debugPrint('⚠️ File $i not in response');
            failedCount++;
            uploadWarnings.add('ไฟล์ ${files[i].path.split('/').last} อัปโหลดไม่สำเร็จ');
            continue;
          }

          final f = uploadedFiles[i];
          final file = files[i];

          final fileUrl = f['fileUrl'] ?? f['file_url'] ?? '';
          final fileType = f['fileType'] ?? f['file_type'] ?? '';
          final originalName = f['originalName'] ?? f['original_name'] ?? file.path.split('/').last;
          final fileName = f['fileName'] ?? f['file_name'] ?? '';

          if (fileUrl.isEmpty || fileType.isEmpty) {
            debugPrint('⚠️ File $i has empty URL or type');
            failedCount++;
            uploadWarnings.add('ไฟล์ $originalName มีข้อมูลไม่สมบูรณ์');
            continue;
          }

          attachments.add({
            'file_url': fileUrl,
            'file_type': fileType,
            'original_name': originalName,
            'file_name': originalName,
            'file_blob_name': fileName,
            'file_size': await file.length(),
          });
          
          successCount++;
          debugPrint('✅ Added attachment: $originalName');
        } catch (e) {
          debugPrint('⚠️ Error processing file $i: $e');
          failedCount++;
          uploadWarnings.add('ไฟล์ ${files[i].path.split('/').last} เกิดข้อผิดพลาด');
        }
      }

      debugPrint('✅ Upload result: $successCount success, $failedCount failed');

      // Return true only if ALL files succeeded
      if (failedCount > 0 && successCount == 0) {
        // ALL FAILED
        debugPrint('❌ All files failed to upload');
        return false;
      } else if (failedCount > 0) {
        // PARTIAL SUCCESS
        debugPrint('⚠️ Some files failed: $successCount/${ files.length} succeeded');
        return true; // Still return true but with warnings
      }
      
      // ALL SUCCESS
      return successCount > 0;
    } catch (e, stack) {
      debugPrint('❌ Upload error: $e');
      debugPrint('❌ Stack: $stack');
      return false;
    }
  }

  /// REMOVE ATTACHMENT
  Future<void> removeAttachment(int index) async {
    if (index < 0 || index >= attachments.length) return;

    final file = attachments[index];
    
    // ไม่ต้องลบจาก Blob ถ้าเป็น Link
    final isLink = file['file_type'] == 'link';
    
    if (!isLink && file['file_blob_name'] != null) {
      try {
        await apiClient.delete(
          '/deleteFile/social-feed',
          data: {
            'fileNames': [file['file_blob_name']],
          },
        );
      } catch (e) {
        debugPrint('⚠️ Failed to delete file from blob: $e');
      }
    }

    attachments.removeAt(index);
  }

  /// FETCH FILE SIZES FROM BLOB (for edit mode)
  Future<void> _fetchFileSizesFromBlob() async {
    try {
      debugPrint('📏 Fetching file sizes from blob...');
      
      for (int i = 0; i < attachments.length; i++) {
        final attachment = attachments[i];
        final fileUrl = attachment['file_url'] as String?;
        
        if (fileUrl == null || fileUrl.isEmpty) continue;
        if (attachment['file_size'] != null && attachment['file_size'] > 0) continue;
        
        try {
          // Use HTTP HEAD request to get file size
          final response = await http.head(Uri.parse(fileUrl));
          
          if (response.statusCode == 200) {
            final contentLength = response.headers['content-length'];
            if (contentLength != null) {
              final fileSize = int.tryParse(contentLength) ?? 0;
              
              // Update attachment with real file size
              attachments[i] = {
                ...attachment,
                'file_size': fileSize,
              };
              
              debugPrint('📏 File size fetched: ${attachment['file_name']} = $fileSize bytes');
            }
          }
        } catch (e) {
          debugPrint('⚠️ Failed to fetch size for: ${attachment['file_name']}');
        }
      }
      
      debugPrint('✅ File sizes fetched successfully');
    } catch (e) {
      debugPrint('❌ Error fetching file sizes: $e');
    }
  }

  Future<Map<String, dynamic>> submitPost() async {
    try {
      isLoading.value = true;
      debugPrint('📝 Submitting post... mode=${mode.value}');

      Map<String, dynamic> result;
      if (mode.value == CreatePostMode.edit) {
        result = await _updatePost();
      } else {
        result = await _createPost();
      }

      debugPrint('✅ Submit result: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Submit error: $e');
      rethrow;
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

    // ส่ง sectionIds (รองรับ multiple sections)
    return postRepository.createPost(
      sectionIds: effectiveSectionIds,
      title: effectiveTitle,
      content: content.value,
      postType: postType.value,
      isAnonymous: isAnonymous.value,
      attachments: attachments,
      // Assignment-specific fields
      dueDate: dueDate.value?.toIso8601String(),
      maxScore: maxScore.value,
      isGroup: isGroup.value,
      groups: groups.toList(),
    );
  }

  Future<Map<String, dynamic>> _updatePost() async {
    try {
      final isTeacher =
          auth.roleName.value == 'teacher' || auth.roleName.value == 'instructor';

      return await postRepository.updatePost(
        postContentId: editingPostContentId!,
        title: title.value,
        content: content.value,
        attachments: attachments.toList(),
        // Assignment fields (only for teacher + assignment type)
        dueDate: isTeacher && postType.value == 'assignment'
            ? dueDate.value?.toIso8601String()
            : null,
        maxScore: isTeacher && postType.value == 'assignment'
            ? maxScore.value
            : null,
        isGroup: isTeacher && postType.value == 'assignment'
            ? isGroup.value
            : null,
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
