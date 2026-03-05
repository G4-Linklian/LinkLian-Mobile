import 'dart:io';

import 'package:LinkLian/features/classes/presentation/widgets/attachment_file.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/linklian-icon.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/utils/file_picker_helper.dart';
import '../controllers/create_post_community_controller.dart';

class CreatePostCommunityPage extends StatefulWidget {
  const CreatePostCommunityPage({super.key});

  @override
  State<CreatePostCommunityPage> createState() =>
      _CreatePostCommunityPageState();
}

class _CreatePostCommunityPageState extends State<CreatePostCommunityPage> {
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<CreatePostCommunityController>();
    _contentController = controller.contentController;
  }

  Future<void> _handleClose(CreatePostCommunityController controller) async {
    final hasContent =
        controller.contentController.text.trim().isNotEmpty ||
        controller.selectedFiles.isNotEmpty;

    if (!hasContent) {
      Get.back();
      return;
    }

    final shouldClose = await Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.primaryPalette[300],
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                controller.isEditMode.value
                    ? 'ยกเลิกการแก้ไขโพสต์?'
                    : 'ยกเลิกการสร้างโพสต์?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryPalette[700],
                ),
              ),

              const SizedBox(height: 16),

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

              Row(
                children: [
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
                        "โพสต์ต่อ",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        "ยกเลิกการโพสต์",
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
  }

  void _showImagePickerOptions(CreatePostCommunityController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'เลือกรูปภาพ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryPalette[800],
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: AppColors.primaryPalette[600],
                ),
                title: const Text('เลือกจากแกลเลอรี'),
                onTap: () async {
                  Get.back();
                  await controller.pickImageFromGallery();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: AppColors.primaryPalette[600],
                ),
                title: const Text('ถ่ายรูป'),
                onTap: () async {
                  Get.back();
                  await controller.pickImageFromCamera();
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('ยกเลิก'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CreatePostCommunityController>();

    return WillPopScope(
      onWillPop: () async {
        await _handleClose(controller);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.white,

        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,
          title: Obx(
            () => Text(
              controller.isEditMode.value ? "แก้ไขโพสต์" : "สร้างโพสต์",
              style: const TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          leading: const SizedBox(),
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
            // CONTENT AREA + ATTACHMENTS
            Expanded(
              child: Column(
                children: [
                  // CONTENT INPUT 
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(
                            () => CircleAvatar(
                              radius: 22,
                              backgroundImage:
                                  controller.userProfileImage.value.isNotEmpty
                                  ? NetworkImage(
                                      controller.userProfileImage.value,
                                    )
                                  : null,
                              backgroundColor: const Color(0xFFEEDBC9),
                              child: controller.userProfileImage.value.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: TextField(
                              controller: _contentController,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.black,
                              ),
                              decoration: InputDecoration(
                                hintText: "พูดคุยกับชุมชนของคุณได้เลย!",
                                hintStyle: TextStyle(
                                  color: Colors.grey.withOpacity(0.5),
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ATTACHMENTS
                  Obx(() {
                    if (controller.filesPreviews.isEmpty) {
                      return const SizedBox();
                    }

                    return Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primaryPalette[600]!,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Scrollbar(
                          trackVisibility: true,
                          thumbVisibility: true,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            itemCount: controller.filesPreviews.length,
                            itemBuilder: (context, index) {
                              final file = controller.filesPreviews[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                ),
                                child: AttachmentTile(
                                  file: file,
                                  onRemove: () =>
                                      controller.removeAttachment(index),
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

            // BOTTOM BAR - Tools + Post Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                ),
              ),
              child: SafeArea(
                child: Row(
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
                          DialogHelper.hideLoading();
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


                    IconButton(
                      icon: const Icon(
                        LinkLianIcon.photo,
                        color: AppColors.black,
                        size: 24,
                      ),
                      onPressed: () => _showImagePickerOptions(controller),
                    ),


                    IconButton(
                      icon: const Icon(
                        LinkLianIcon.link,
                        color: AppColors.black,
                        size: 24,
                      ),
                      onPressed: () => _showLinkDialog(context, controller),
                    ),

                    const Spacer(),

                    _buildPostButton(controller: controller),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLinkDialog(
    BuildContext context,
    CreatePostCommunityController controller,
  ) {
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(LinkLianIcon.link, color: AppColors.primaryPalette[600]),
            const SizedBox(width: 8),
            const Text("แนบลิงก์"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                hintText: "https://...",
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
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("ยกเลิก")),
          ElevatedButton(
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isEmpty) return;

              if (!url.startsWith('http://') && !url.startsWith('https://')) {
                DialogHelper.showNotification(
                  title: 'ลิงก์ไม่ถูกต้อง',
                  message: 'กรุณาใส่ลิงก์ที่ขึ้นต้นด้วย http:// หรือ https://',
                  type: NotificationType.warning,
                );
                return;
              }

              controller.addLink(url);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPalette[500],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "เพิ่ม",
              style: TextStyle(color: AppColors.primaryPalette[900]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostButton({required CreatePostCommunityController controller}) {
    return Obx(
      () => GestureDetector(
        onTap: controller.isSubmitting.value
            ? null
            : () async {
                try {
                  await controller.submitPost();
                } catch (e) {
                  // Error already handled in controller
                }
              },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: controller.isSubmitting.value
                ? AppColors.primaryPalette[300]
                : AppColors.primaryPalette[500],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                controller.isEditMode.value ? "บันทึก" : "โพสต์",
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(LinkLianIcon.post, size: 18, color: AppColors.white),
            ],
          ),
        ),
      ),
    );
  }
}