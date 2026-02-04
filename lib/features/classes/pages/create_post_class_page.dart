import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/utils/file_picker_helper.dart';
import '../../../core/constants/linklian-icon.dart';

import '../../auth/controller/auth_controller.dart';
import '../controllers/class_feed_controller.dart';
import '../controllers/create_post_controller.dart';
import '../controllers/class_detail_controller.dart';
import '../widgets/class_selector.dart';
import '../widgets/attachment_file.dart';
import '../widgets/attachment_picture.dart';

class CreatePostClassPage extends StatefulWidget {
  const CreatePostClassPage({super.key});

  @override
  State<CreatePostClassPage> createState() => _CreatePostClassPageState();
}

class _CreatePostClassPageState extends State<CreatePostClassPage> {
  late TextEditingController _contentController;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    
    final controller = Get.find<CreatePostController>();


    _contentController = TextEditingController(text: controller.content.value);
    _titleController = TextEditingController(text: controller.title.value);

    _contentController.addListener(() {
      controller.content.value = _contentController.text;
    });

    _titleController.addListener(() {
      controller.title.value = _titleController.text;
    });

  }

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  /// Handle close button with confirmation if content exists
  Future<void> _handleClose(CreatePostController controller) async {
    // Check if user has entered any content
    if (controller.hasContent) {
      final shouldClose = await Get.dialog<bool>(
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: AppColors.primaryPalette[300],
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  'ยกเลิกการสร้างโพสต์?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryPalette[700],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Content
                Text(
                  'คุณได้พิมพ์ข้อความหรือแนบไฟล์แล้ว\nหากยกเลิกข้อมูลทั้งหมดจะหายไป',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryPalette[700],
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  children: [
                    // โพสต์ต่อ button (left)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Get.back(result: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPalette[500],
                          foregroundColor: AppColors.primaryPalette[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: const Text(
                          'โพสต์ต่อ',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // ยกเลิกการโพสต์ button (right)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Get.back(result: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.dangerPalette[500],
                          foregroundColor: AppColors.dangerPalette[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: const Text(
                          'ยกเลิกการโพสต์',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

      if (shouldClose == true) {
        Get.back();
      }
    } else {
      // No content, just close
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final CreatePostController controller = Get.find<CreatePostController>();
    final classFeedController = Get.find<ClassFeedController>();
    final auth = Get.find<AuthController>();
    final isTeacher =
        auth.roleName.value == 'teacher' || auth.roleName.value == 'instructor';

    return WillPopScope(
      onWillPop: () async {
        // Handle Android back button
        if (controller.hasContent) {
          await _handleClose(controller);
          return false; // Prevent default back behavior
        }
        return true; // Allow back if no content
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: const SizedBox(),
          title: Obx(
            () => Text(
              controller.mode.value == CreatePostMode.edit
                  ? 'แก้ไขโพสต์'
                  : 'สร้างโพสต์',
              style: const TextStyle(
                color: AppColors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                icon: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.dangerPalette[500]!,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    LinkLianIcon.close,
                    color: AppColors.dangerPalette[500],
                    size: 16,
                  ),
                ),
                onPressed: () => _handleClose(controller),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              child: Row(
                children: [
                  ClassSelector(
                    controller: controller,
                    classFeedController: classFeedController,
                  ),
                  const Spacer(),
                  Obx(() {
                    // ===== นักเรียน =====
                    if (!isTeacher) {
                      return _buildTagChip(
                        label: 'คำถาม',
                        isSelected: controller.postType.value == 'question',
                        onTap: () {
                          controller.postType.value = 'question';
                        },
                      );
                    }

                    // ===== ครู =====
                    return Row(
                      children: [
                        _buildTagChip(
                          label: 'ประกาศ',
                          isSelected: controller.postType.value == 'announcement',
                          onTap: () {
                            controller.postType.value = 'announcement';
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildTagChip(
                          label: 'การบ้าน',
                          isSelected: controller.postType.value == 'assignment',
                          onTap: () {
                            controller.postType.value = 'assignment';
                          },
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),

            // CONTENT AREA + ATTACHMENTS (Scrollable together)
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    // CONTENT INPUT
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(AppSizes.md),
                        child: isTeacher
                            ? _buildTeacherContent(controller)
                            : _buildStudentContent(controller),
                      ),
                    ),

                    // ATTACHMENTS (under content, scrollable)
                    Obx(() {
                      if (controller.attachments.isEmpty) {
                        return const SizedBox();
                      }

                      return Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primaryPalette[600]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Scrollbar(
                            trackVisibility: true,
                            thumbVisibility: true,
                            child: ListView.builder(
                              scrollDirection: Axis.vertical,
                              shrinkWrap: true,
                              itemCount: controller.attachments.length,
                              itemBuilder: (context, index) {
                                final file = controller.attachments[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  child: AttachmentTile(
                                    file: file,
                                    onRemove: () => controller.removeAttachment(index),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // BOTTOM BAR (Toggle + Tools + Post)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Toggle Anonymous - เฉพาะนักเรียน
                    if (!isTeacher)
                      Obx(() {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _buildIconToggleSwitch(
                              value: controller.isAnonymous.value,
                              onChanged: (v) => controller.isAnonymous.value = v,
                            ),
                          ),
                        );
                      }),

                    // Tools + Post Button
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            LinkLianIcon.paperclip,
                            color: AppColors.black,
                            size: 24,
                          ),
                          onPressed: () async {
                            final files = await FilePickerHelper.pickFiles();
                            if (files.isEmpty) return;

                            try {
                              DialogHelper.showLoading('กำลังอัปโหลดไฟล์...');
                              final success = await controller.uploadFiles(files);
                              DialogHelper.hideLoading();
                              
                              if (!success) {
                                // DANGER: ไม่สามารถอัปโหลดได้เลย
                                DialogHelper.showNotification(
                                  title: 'อัปโหลดล้มเหลว',
                                  message: 'ไม่สามารถอัปโหลดไฟล์ได้ กรุณาตรวจสอบไฟล์และลองใหม่อีกครั้ง',
                                  type: NotificationType.error,
                                );
                              } else if (controller.uploadWarnings.isNotEmpty) {
                                // WARNING: บางไฟล์มีปัญหา
                                DialogHelper.showNotification(
                                  title: 'อัปโหลดสำเร็จบางส่วน',
                                  message: controller.uploadWarnings.join('\n'),
                                  type: NotificationType.warning,
                                );
                              }
                            } catch (e) {
                              DialogHelper.hideLoading();
                              DialogHelper.showNotification(
                                title: 'เกิดข้อผิดพลาด',
                                message: 'ไม่สามารถอัปโหลดไฟล์ได้: $e',
                                type: NotificationType.error,
                              );
                            }
                          },
                        ),

                        CreatePostImagePickerButton(
                          controller: controller,
                          icon: const Icon(
                            LinkLianIcon.photo,
                            color: AppColors.black,
                            size: 24,
                          ),
                        ),

                        IconButton(
                          icon: const Icon(
                            LinkLianIcon.link,
                            color: AppColors.black,
                            size: 24,
                          ),
                          onPressed: () {
                            _showLinkDialog(context, controller);
                          },
                        ),

                        const Spacer(),
                        _buildPostButton(controller: controller, isTeacher: isTeacher),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UI สำหรับนักเรียน - เฉพาะ content
  Widget _buildStudentContent(CreatePostController controller) {
    return TextField(
      controller: _contentController,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: 'มีคำถามจะถามใช่ไหม...',
        hintStyle: const TextStyle(
          color: AppColors.gray,
          fontSize: 16,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  // UI สำหรับครู - title + content
  Widget _buildTeacherContent(CreatePostController controller) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== TITLE FIELD =====
          TextField(
            controller: _titleController,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: controller.postType.value == 'assignment'
                  ? 'ชื่อการบ้าน'
                  : 'ชื่อประกาศ',
              hintStyle: TextStyle(
                color: AppColors.gray.withOpacity(0.6),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEEEEEE), height: 1),
          const SizedBox(height: 16),

          // ===== CONTENT FIELD =====
          TextField(
            controller: _contentController,
            maxLines: null,
            expands: false,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(fontSize: 15),
            minLines: 8,
            decoration: InputDecoration(
              hintText: controller.postType.value == 'assignment'
                  ? 'อธิบายรายละเอียดการบ้าน...'
                  : 'พิมพ์ประกาศถึงนักเรียน...',
              hintStyle: const TextStyle(
                color: AppColors.gray,
                fontSize: 15,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _buildTagChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.buttonPalette[100]
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.buttonPalette[300]!
                : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.buttonPalette[700]
                : const Color(0xFF757575),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildIconToggleSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 72,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: value
              ? AppColors.primaryPalette[300]
              : AppColors.primaryPalette[100],
          border: Border.all(
            color: value
                ? AppColors.primaryPalette[500]!
                : AppColors.primaryPalette[300]!,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  LinkLianHugeIcon.anonymous(
                    size: 18,
                    color: value
                        ? AppColors.primaryPalette[500]!
                        : AppColors.primaryPalette[300]!,
                  ),
                  Icon(
                    LinkLianIcon.identifiedUser,
                    size: 18,
                    color: !value
                        ? AppColors.primaryPalette[500]
                        : AppColors.primaryPalette[100],
                  ),
                ],
              ),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: value ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryPalette[900],
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: value
                    ? LinkLianHugeIcon.anonymous(
                        size: 18,
                        color: AppColors.white,
                      )
                    : Icon(
                        LinkLianIcon.identifiedUser,
                        size: 18,
                        color: AppColors.white,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show dialog to add link attachment
  void _showLinkDialog(BuildContext context, CreatePostController controller) {
    final urlController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(LinkLianIcon.link, color: AppColors.primaryPalette[600]),
            const SizedBox(width: 8),
            const Text('แนบลิงก์'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                hintText: 'https://linklian.com',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.url,
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              'ลิงก์จะแสดงเป็น preview และเปิดใน browser เมื่อกด',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isEmpty) {
                return;
              }
              
              // Validate URL format
              if (!url.startsWith('http://') && !url.startsWith('https://')) {
                DialogHelper.showNotification(
                  title: 'ลิงก์ไม่ถูกต้อง',
                  message: 'กรุณาใส่ลิงก์ที่ขึ้นต้นด้วย http:// หรือ https://',
                  type: NotificationType.warning,
                );
                return;
              }
              
              // Add link to attachments (ไม่ต้อง upload ไปที่ Blob)
              controller.attachments.add({
                'file_type': 'link',
                'file_url': url,
                'file_name': url,
                'original_name': url,
                'file_size': 0,
              });
              
              Navigator.pop(ctx);
              
              debugPrint('🔗 Link added: $url');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPalette[500],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('เพิ่มลิงก์', style: TextStyle(color: AppColors.primaryPalette[900])),
          ),
        ],
      ),
    );
  }

  Widget _buildPostButton({
    required CreatePostController controller,
    required bool isTeacher,
  }) {
    return GestureDetector(
      onTap: () async {
        // ===== VALIDATION =====
        if (controller.postType.value.isEmpty) {
          DialogHelper.showErrorDialog(description: 'กรุณาเลือกประเภทโพสต์');
          return;
        }

        if (!controller.isAllSelected &&
            controller.selectedSectionIds.isEmpty) {
          DialogHelper.showErrorDialog(
            description: 'กรุณาเลือกอย่างน้อย 1 คลาส',
          );
          return;
        }

        // เช็ค title สำหรับครู
        if (isTeacher && controller.title.value.trim().isEmpty) {
          DialogHelper.showErrorDialog(description: 'กรุณากรอกชื่อโพสต์');
          return;
        }

        if (controller.content.value.trim().isEmpty) {
          DialogHelper.showErrorDialog(description: 'กรุณากรอกเนื้อหาโพสต์');
          return;
        }

        // Note: ไม่ต้องเช็คไฟล์แนบ เพราะโพสต์โดยไม่มีไฟล์ก็ได้

        // ===== SUBMIT =====
        try {
          DialogHelper.showLoading('กำลังโพสต์...');

          debugPrint('📝 Starting submit...');
          final res = await controller.submitPost();
          debugPrint('📝 Submit response: $res');
          
          DialogHelper.hideLoading();

          // Check for success - handle both formats
          final isSuccess = res['success'] == true || 
                            res['data'] != null ||
                            res['post_content_id'] != null;
          
          if (!isSuccess) {
            debugPrint('❌ Post failed: $res');
            DialogHelper.showNotification(
              title: 'เกิดข้อผิดพลาด',
              message: res['error']?['message'] ?? 'ไม่สามารถสร้างโพสต์ได้',
              type: NotificationType.error,
            );
            return;
          }

          debugPrint('✅ Post success!');

          // Show notification
          if (res['warning'] != null && (res['warning'] as List).isNotEmpty) {
            DialogHelper.showNotification(
              title: 'โพสต์สำเร็จ',
              message: res['warning'][0]['message'],
              type: NotificationType.warning,
            );
          } else {
            DialogHelper.showNotification(
              title: 'โพสต์สำเร็จ',
              message: 'ระบบได้บันทึกโพสต์ของคุณเรียบร้อยแล้ว',
              type: NotificationType.success,
            );
          }

          // Wait for notification AND close all dialogs
          await Future.delayed(const Duration(milliseconds: 1500));
          
          // Close any remaining dialogs/snackbars
          if (Get.isSnackbarOpen == true) {
            Get.closeAllSnackbars();
          }
          if (Get.isDialogOpen == true) {
            Get.back();
          }

          debugPrint('📍 Starting redirect...');
          debugPrint('📍 Mode: ${controller.mode.value}');
          debugPrint('📍 Source: ${controller.source}');
          debugPrint('📍 Selected sections: ${controller.selectedSectionIds}');

          // ===== REDIRECT BASED ON SOURCE AND MODE =====
          if (controller.mode.value == CreatePostMode.edit) {
            // EDIT MODE: Go back and refresh class detail
            debugPrint('📍 Edit mode: Going back');
            
            // Go back FIRST - this must happen immediately
            Navigator.of(context).pop({
              'success': true,
              'edited': true,
              'post': {
                'post_content_id': controller.editingPostContentId,
                'title': isTeacher
                    ? controller.title.value
                    : controller.content.value,
                'content': controller.content.value,
                'post_type': controller.postType.value,
                'attachments': controller.attachments,
              },
            });
            
            // Refresh class detail AFTER pop
            Future.delayed(const Duration(milliseconds: 300), () {
              if (Get.isRegistered<ClassDetailController>()) {
                debugPrint('📍 Refreshing class detail after edit...');
                Get.find<ClassDetailController>().fetchPosts(keepScroll: true);
              }
            });
            
            return; // Exit early after edit
          } else if (controller.source == CreatePostSource.classDetail) {
            // POSTED FROM CLASS DETAIL: Go back and refresh
            debugPrint('📍 From class detail: Going back with refresh');
            
            // ✅ ใช้ Navigator.pop แทน Get.until เพราะ ClassDetailPage ไม่ได้เป็น named route
            Navigator.of(context).pop({
              'success': true,
              'refresh': true,
            });

            // Trigger refresh after going back
            await Future.delayed(const Duration(milliseconds: 200));
            if (Get.isRegistered<ClassDetailController>()) {
              debugPrint('📍 Refreshing class detail...');
              final detailController = Get.find<ClassDetailController>();
              await detailController.fetchPosts();
              detailController.scrollToTop();
            }
          } else {
            // POSTED FROM CLASS FEED
            debugPrint('📍 From class feed');
            
            if (controller.selectedSectionIds.length == 1) {
              // SINGLE CLASS: Navigate to that class detail
              final sectionId = controller.selectedSectionIds.first;
              debugPrint('📍 Single class ($sectionId): Navigate to class detail');
              
              // Close create post page
              Get.back();

              // Navigate to class detail
              await Future.delayed(const Duration(milliseconds: 200));
              Get.toNamed(
                '/class-detail',
                arguments: {
                  'sectionId': sectionId,
                  'refresh': true,
                },
              );
            } else {
              // MULTIPLE CLASSES or ALL: Go back to class feed
              debugPrint('📍 Multiple classes: Going back to feed');
              
              // Close create post page first
              Get.until((route) {
                debugPrint('📍 Checking route: ${route.settings.name}');
                // Go back until we reach a page that's NOT create-post
                return route.settings.name != '/create-post' && 
                       route.settings.name != '/CreatePostClassPage';
              });

              // Refresh class feed
              await Future.delayed(const Duration(milliseconds: 200));
              if (Get.isRegistered<ClassFeedController>()) {
                debugPrint('📍 Refreshing class feed...');
                Get.find<ClassFeedController>().refreshFeed();
              }
            }
          }
        } on DioException catch (e) {
          debugPrint('❌ DioException: ${e.message}');
          debugPrint('❌ Response: ${e.response?.data}');
          DialogHelper.hideLoading();
          
          final responseData = e.response?.data;
          String errorMessage = 'ระบบขัดข้อง กรุณาลองใหม่';
          
          if (responseData is Map) {
            errorMessage = responseData['message']?.toString() ?? 
                           responseData['error']?.toString() ?? 
                           errorMessage;
          }

          DialogHelper.showNotification(
            title: 'เกิดข้อผิดพลาด',
            message: errorMessage,
            type: NotificationType.error,
          );
        } catch (e, stack) {
          debugPrint('❌ Error: $e');
          debugPrint('❌ Stack: $stack');
          DialogHelper.hideLoading();
          DialogHelper.showNotification(
            title: 'เกิดข้อผิดพลาด',
            message: 'ไม่สามารถสร้างโพสต์ได้: $e',
            type: NotificationType.error,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryPalette[500],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              controller.mode.value == CreatePostMode.edit ? 'บันทึก' : 'โพสต์',
              style: const TextStyle(color: AppColors.white),
            ),
            const SizedBox(width: 6),
            Icon(LinkLianIcon.post, size: 18, color: AppColors.white),
          ],
        ),
      ),
    );
  }
}