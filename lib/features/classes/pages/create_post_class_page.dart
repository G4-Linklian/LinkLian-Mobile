import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
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

  @override
  Widget build(BuildContext context) {
    final CreatePostController controller = Get.find<CreatePostController>();
    final classFeedController = Get.find<ClassFeedController>();
    final auth = Get.find<AuthController>();
    final isTeacher =
        auth.roleName.value == 'teacher' || auth.roleName.value == 'instructor';

    return Scaffold(
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
                  color: AppColors.dangerPalette![500],
                  size: 16,
                ),
              ),
              onPressed: () => Get.back(),
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

          // CONTENT AREA แตกต่างตามบทบาท
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                ),
              ),
              child: isTeacher
                  ? _buildTeacherContent(controller)
                  : _buildStudentContent(controller),
            ),
          ),

          // ATTACHMENTS
          Obx(() {
            if (controller.attachments.isEmpty) {
              return const SizedBox();
            }

            return Column(
              children: controller.attachments.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;

                return AttachmentTile(
                  file: file,
                  onRemove: () => controller.removeAttachment(index),
                );
              }).toList(),
            );
          }),

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
                            await controller.uploadFiles(files);
                          } catch (e) {
                            DialogHelper.showNotification(
                              title: 'อัปโหลดไม่สำเร็จ',
                              message: 'กรุณาลองใหม่อีกครั้ง',
                              type: NotificationType.error,
                            );
                          } finally {
                            DialogHelper.hideLoading();
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
                          DialogHelper.showLinkDialog(
                            onSubmit: (url) {
                            },
                          );
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

        // ===== SUBMIT =====
        try {
          DialogHelper.showLoading('กำลังโพสต์...');

          final res = await controller.submitPost();
          DialogHelper.hideLoading();

          if (res.isEmpty || res['success'] != true) {
            DialogHelper.showNotification(
              title: 'เกิดข้อผิดพลาด',
              message: res['error']?['message'] ?? 'ไม่สามารถสร้างโพสต์ได้',
              type: NotificationType.error,
            );
            return;
          }

          if (res['warning'] != null && res['warning'].isNotEmpty) {
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

          await Future.delayed(const Duration(seconds: 1));
          Get.back(
            result: {
              'success': true,
              'edited': controller.mode.value == CreatePostMode.edit,
              'post': {
                'post_content_id': controller.editingPostContentId,
                'title': isTeacher 
                    ? controller.title.value 
                    : controller.content.value, 
                'content': controller.content.value,
                'post_type': controller.postType.value,
                'attachments': controller.attachments,
              },
            },
            closeOverlays: true,
          );
        } on DioError catch (e) {
          DialogHelper.hideLoading();
          final err = e.response?.data?['error'];

          DialogHelper.showNotification(
            title: 'เกิดข้อผิดพลาด',
            message: err?['message'] ?? 'ระบบขัดข้อง กรุณาลองใหม่',
            type: NotificationType.error,
          );
        } catch (e) {
          DialogHelper.hideLoading();
          DialogHelper.showNotification(
            title: 'เกิดข้อผิดพลาด',
            message: 'ไม่สามารถสร้างโพสต์ได้',
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