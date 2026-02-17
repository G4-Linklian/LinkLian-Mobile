import 'package:LinkLian/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
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
  late TextEditingController _maxScoreController;
  late final ScrollController _attachmentScrollController;

  @override
  void initState() {
    super.initState();

    final controller = Get.find<CreatePostController>();

    _contentController = TextEditingController(text: controller.content.value);
    _titleController = TextEditingController(text: controller.title.value);
    _maxScoreController = TextEditingController(
      text: controller.maxScore.value.toString(),
    );

    _contentController.addListener(() {
      controller.content.value = _contentController.text;
    });

    _titleController.addListener(() {
      controller.title.value = _titleController.text;
    });

    _maxScoreController.addListener(() {
      controller.maxScore.value =
          double.tryParse(_maxScoreController.text) ?? 100;
    });

    _attachmentScrollController = ScrollController();
  }

  @override
  void dispose() {
    _attachmentScrollController.dispose();
    _contentController.dispose();
    _titleController.dispose();
    _maxScoreController.dispose();
    super.dispose();
  }

  /// Handle close button with confirmation if content exists
  Future<void> _handleClose(CreatePostController controller) async {
    switch (controller.closeAction) {
      case ClosePostAction.closeImmediately:
        Get.back();
        return;

      case ClosePostAction.confirmDiscardEdit:
        final shouldClose = await _showDiscardEditDialog();
        if (shouldClose == true) {
          Get.back();
        }
        return;

      case ClosePostAction.confirmDiscardCreate:
        final shouldClose = await _showDiscardCreateDialog();
        if (shouldClose == true) {
          Get.back();
        }
        return;
    }
  }

  Future<bool?> _showDiscardEditDialog() {
    return Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.primaryPalette[300],
        child: _DiscardDialogContent(
          title: 'ยกเลิกการแก้ไข?',
          description: 'คุณได้แก้ไขเนื้อหาแล้ว\nหากยกเลิกการเปลี่ยนแปลงจะหายไป',
          cancelText: 'แก้ไขต่อ',
          confirmText: 'ยกเลิกแก้ไข',
        ),
      ),
      barrierDismissible: false,
    );
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
            // ROW 1: Class Selector + Post Type Chips
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
                    final isEditMode =
                        controller.mode.value == CreatePostMode.edit;
                    final isPostTypeLocked = controller.isPostTypeLocked.value;

                    // ===== นักเรียน =====
                    if (!isTeacher) {
                      return Opacity(
                        opacity: isEditMode ? 0.4 : 1.0,
                        child: _buildTagChip(
                          label: 'คำถาม',
                          isSelected: controller.postType.value == 'question',
                          onTap: isEditMode
                              ? () {}
                              : () {
                                  controller.postType.value = 'question';
                                },
                        ),
                      );
                    }

                    // ===== ครู =====
                    return Row(
                      children: [
                        Opacity(
                          opacity:
                              (isEditMode &&
                                      controller.postType.value !=
                                          'assignment') ||
                                  (isPostTypeLocked &&
                                      controller.postType.value != 'assignment')
                              ? 0.4
                              : 1.0,
                          child: _buildTagChip(
                            label: 'การบ้าน',
                            isSelected:
                                controller.postType.value == 'assignment',
                            onTap: (isEditMode || isPostTypeLocked)
                                ? () {}
                                : () {
                                    controller.postType.value = 'assignment';
                                  },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Opacity(
                          opacity:
                              (isEditMode &&
                                      controller.postType.value !=
                                          'announcement') ||
                                  (isPostTypeLocked &&
                                      controller.postType.value !=
                                          'announcement')
                              ? 0.4
                              : 1.0,
                          child: _buildTagChip(
                            label: 'ประกาศ',
                            isSelected:
                                controller.postType.value == 'announcement',
                            onTap: (isEditMode || isPostTypeLocked)
                                ? () {}
                                : () {
                                    controller.postType.value = 'announcement';
                                  },
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),

            // ROW 2: Assignment Type Dropdown (เฉพาะครู + เมื่อเลือกการบ้าน)
            if (isTeacher)
              Obx(() {
                if (controller.postType.value != 'assignment') {
                  return const SizedBox();
                }

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      // Calendar icon (ซ้าย)
                      GestureDetector(
                        onTap: () => _showDateTimePicker(context, controller),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPalette[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primaryPalette[300]!,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: AppColors.primaryPalette[600],
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Dropdown ประเภทการบ้าน (ขวา)
                      _buildAssignmentTypeChip(controller),
                    ],
                  ),
                );
              }),

            // ROW 3: Due date display (เฉพาะครู + เมื่อเลือกวันแล้ว)
            if (isTeacher)
              Obx(() {
                if (controller.postType.value != 'assignment' ||
                    controller.dueDate.value == null) {
                  return const SizedBox();
                }

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: 4,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => _showDateTimePicker(context, controller),
                      child: Text(
                        'กำหนดส่ง : ${controller.dueDate.value!.day}/${controller.dueDate.value!.month}/${controller.dueDate.value!.year}  ${controller.dueDate.value!.hour.toString().padLeft(2, '0')}:${controller.dueDate.value!.minute.toString().padLeft(2, '0')} น.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primaryPalette[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }),

            // CONTENT AREA + ATTACHMENTS
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

                    // ATTACHMENTS
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
                            border: Border.all(
                              color: AppColors.primaryPalette[600]!,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Scrollbar(
                            controller: _attachmentScrollController,
                            trackVisibility: true,
                            thumbVisibility: true,
                            child: ListView.builder(
                              controller: _attachmentScrollController,
                              scrollDirection: Axis.vertical,
                              shrinkWrap: true,
                              itemCount: controller.attachments.length,
                              itemBuilder: (context, index) {
                                final file = controller.attachments[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
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
            ),

            // BOTTOM BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    // ROW: คะแนน (ซ้าย) + โพสต์ (ขวา) - เฉพาะครู + การบ้าน
                    if (isTeacher)
                      Obx(() {
                        if (controller.postType.value != 'assignment') {
                          return const SizedBox();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              // คะแนน : chip style
                              _buildScoreInput(controller),
                              const Spacer(),
                              _buildPostButton(
                                controller: controller,
                                isTeacher: isTeacher,
                              ),
                            ],
                          ),
                        );
                      }),

                    // Toggle Anonymous - เฉพาะนักเรียน
                    if (!isTeacher)
                      Obx(() {
                        final isEditMode =
                            controller.mode.value == CreatePostMode.edit;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Opacity(
                              opacity: isEditMode ? 0.4 : 1.0,
                              child: IgnorePointer(
                                ignoring: isEditMode,
                                child: _buildIconToggleSwitch(
                                  value: controller.isAnonymous.value,
                                  onChanged: (v) =>
                                      controller.isAnonymous.value = v,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),

                    // Tools row + Post button (โพสต์อยู่ขวาเมื่อไม่ใช่ assignment)
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
                              final success = await controller.uploadFiles(
                                files,
                              );
                              DialogHelper.hideLoading();

                              if (!success) {
                                DialogHelper.showNotification(
                                  title: 'อัปโหลดล้มเหลว',
                                  message:
                                      'ไม่สามารถอัปโหลดไฟล์ได้ กรุณาตรวจสอบไฟล์และลองใหม่อีกครั้ง',
                                  type: NotificationType.error,
                                );
                              } else if (controller.uploadWarnings.isNotEmpty) {
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

                        // Post button - แสดงตรงนี้เฉพาะเมื่อไม่ใช่ assignment (assignment แสดงบน)
                        if (isTeacher)
                          Obx(() {
                            if (controller.postType.value == 'assignment') {
                              return const SizedBox();
                            }
                            return _buildPostButton(
                              controller: controller,
                              isTeacher: isTeacher,
                            );
                          })
                        else
                          _buildPostButton(
                            controller: controller,
                            isTeacher: isTeacher,
                          ),
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
        hintStyle: const TextStyle(color: AppColors.gray, fontSize: 16),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  // UI สำหรับครู - title + content (ปฏิทิน + ประเภทย้ายไปอยู่ด้านบนแล้ว)
  Widget _buildTeacherContent(CreatePostController controller) {
    return Obx(() {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== TITLE FIELD =====
            TextField(
              controller: _titleController,
              maxLines: 1,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                hintStyle: const TextStyle(color: AppColors.gray, fontSize: 15),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Show date + time picker dialog
  Future<void> _showDateTimePicker(
    BuildContext context,
    CreatePostController controller,
  ) async {
    // 1. Pick date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate:
          controller.dueDate.value ??
          DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryPalette[500]!,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    // 2. Pick time
    if (!context.mounted) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: controller.dueDate.value != null
          ? TimeOfDay.fromDateTime(controller.dueDate.value!)
          : const TimeOfDay(hour: 23, minute: 59),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryPalette[500]!,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    // 3. Combine date + time
    controller.dueDate.value = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  /// Build assignment type chip (ประเภทการบ้าน ▼)
  Widget _buildAssignmentTypeChip(CreatePostController controller) {
    return Obx(() {
      final isEditMode = controller.mode.value == CreatePostMode.edit;

      // ถ้าเป็น edit mode ให้แสดง chip แบบล็อค (ไม่มี dropdown)
      if (isEditMode) {
        return Opacity(
          opacity: 0.4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.buttonPalette[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.buttonPalette[300]!,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.isGroup.value ? 'งานกลุ่ม' : 'งานเดี่ยว',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.buttonPalette[700],
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Create mode: แสดง dropdown ปกติ
      return PopupMenuButton<bool>(
        onSelected: (isGroup) {
          controller.isGroup.value = isGroup;
        },
        offset: const Offset(0, 45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: AppColors.white,
        itemBuilder: (context) => [
          PopupMenuItem<bool>(
            value: false,
            child: Row(
              children: [
                Icon(
                  Icons.person,
                  color: AppColors.primaryPalette[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'งานเดี่ยว',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryPalette[900],
                  ),
                ),
                const Spacer(),
                if (!controller.isGroup.value)
                  Icon(
                    Icons.check,
                    color: AppColors.primaryPalette[600],
                    size: 20,
                  ),
              ],
            ),
          ),
          PopupMenuItem<bool>(
            value: true,
            child: Row(
              children: [
                Icon(
                  Icons.group,
                  color: AppColors.primaryPalette[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'งานกลุ่ม',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryPalette[900],
                  ),
                ),
                const Spacer(),
                if (controller.isGroup.value)
                  Icon(
                    Icons.check,
                    color: AppColors.primaryPalette[600],
                    size: 20,
                  ),
              ],
            ),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.buttonPalette[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.buttonPalette[300]!, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                controller.isGroup.value ? 'งานกลุ่ม' : 'งานเดี่ยว',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.buttonPalette[700],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 20,
                color: AppColors.buttonPalette[700],
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Build score input chip
  Widget _buildScoreInput(CreatePostController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.buttonPalette[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.buttonPalette[300]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'คะแนน : ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.buttonPalette[700],
            ),
          ),
          SizedBox(
            width: 50,
            child: TextField(
              controller: _maxScoreController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
              ],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.buttonPalette[700],
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
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
              : AppColors.gray.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.buttonPalette[300]!
                : AppColors.gray.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.buttonPalette[700]
                : AppColors.black.withOpacity(0.5),
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
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    children: [
                      Icon(
                        LinkLianIcon.link,
                        color: AppColors.primaryPalette[600],
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'แนบลิงก์',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // URL Input
                  TextField(
                    controller: urlController,
                    decoration: InputDecoration(
                      hintText: 'https://linklian.com',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    keyboardType: TextInputType.url,
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),

                  // Submit button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        final url = urlController.text.trim();
                        if (url.isEmpty) {
                          return;
                        }

                        // Validate URL format
                        if (!url.startsWith('http://') &&
                            !url.startsWith('https://')) {
                          DialogHelper.showNotification(
                            title: 'ลิงก์ไม่ถูกต้อง',
                            message:
                                'กรุณาใส่ลิงก์ที่ขึ้นต้นด้วย http:// หรือ https://',
                            type: NotificationType.warning,
                          );
                          return;
                        }

                        // Add link to attachments
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'เพิ่มลิงก์',
                        style: TextStyle(color: AppColors.primaryPalette[900]),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Close button (top right corner with circle border)
            Positioned(
              right: 8,
              top: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
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

        // เช็ค assignment fields
        if (controller.postType.value == 'assignment') {
          if (controller.dueDate.value == null) {
            DialogHelper.showErrorDialog(description: 'กรุณาเลือกวันกำหนดส่ง');
            return;
          }
        }

        // Note: ไม่ต้องเช็คไฟล์แนบ เพราะโพสต์โดยไม่มีไฟล์ก็ได้

        // ===== SUBMIT =====
        try {
          DialogHelper.showLoading('กำลังโพสต์...');

          AppLogger.info('📝 Starting submit...');
          final res = await controller.submitPost();
          AppLogger.info('📝 Submit response: $res');

          DialogHelper.hideLoading();

          // Check for success - handle both formats
          final isSuccess =
              res['success'] == true ||
              res['data'] != null ||
              res['post_content_id'] != null;

          if (!isSuccess) {
            AppLogger.info('❌ Post failed: $res');
            DialogHelper.showNotification(
              title: 'เกิดข้อผิดพลาด',
              message: res['error']?['message'] ?? 'ไม่สามารถสร้างโพสต์ได้',
              type: NotificationType.error,
            );
            return;
          }

          AppLogger.info('✅ Post success!');

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

          AppLogger.info('📍 Starting redirect...');
          AppLogger.info('📍 Mode: ${controller.mode.value}');
          AppLogger.info('📍 Source: ${controller.source}');
          AppLogger.info(
            '📍 Selected sections: ${controller.selectedSectionIds}',
          );

          // ===== REDIRECT BASED ON SOURCE AND MODE =====
          if (controller.mode.value == CreatePostMode.edit) {
            // EDIT MODE: Go back and refresh class detail
            AppLogger.info('📍 Edit mode: Going back');

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
                AppLogger.info('📍 Refreshing class detail after edit...');
                Get.find<ClassDetailController>().fetchPosts(keepScroll: true);
              }
            });

            return; // Exit early after edit
          } else if (controller.source == CreatePostSource.classDetail) {
            // POSTED FROM CLASS DETAIL: Go back and refresh
            AppLogger.info('📍 From class detail: Going back with refresh');
            Navigator.of(context).pop({'success': true, 'refresh': true});

            // Trigger refresh after going back
            await Future.delayed(const Duration(milliseconds: 200));
            if (Get.isRegistered<ClassDetailController>()) {
              AppLogger.info('📍 Refreshing class detail...');
              final detailController = Get.find<ClassDetailController>();
              await detailController.fetchPosts();
              detailController.scrollToTop();
            }
          } else {
            // POSTED FROM CLASS FEED
            AppLogger.info('📍 From class feed');

            if (controller.selectedSectionIds.length == 1) {
              // SINGLE CLASS: Navigate to that class detail
              final sectionId = controller.selectedSectionIds.first;
              AppLogger.info(
                '📍 Single class ($sectionId): Navigate to class detail',
              );

              // Close create post page
              Get.back();

              // Navigate to class detail
              await Future.delayed(const Duration(milliseconds: 200));
              Get.toNamed(
                '/class-detail',
                arguments: {'sectionId': sectionId, 'refresh': true},
              );
            } else {
              // MULTIPLE CLASSES or ALL: Go back to class feed
              AppLogger.info('📍 Multiple classes: Going back to feed');

              // Close create post page first
              Get.until((route) {
                AppLogger.info('📍 Checking route: ${route.settings.name}');
                // Go back until we reach a page that's NOT create-post
                return route.settings.name != '/create-post' &&
                    route.settings.name != '/CreatePostClassPage';
              });

              // Refresh class feed
              await Future.delayed(const Duration(milliseconds: 200));
              if (Get.isRegistered<ClassFeedController>()) {
                AppLogger.info('📍 Refreshing class feed...');
                Get.find<ClassFeedController>().refreshFeed();
              }
            }
          }
        } on DioException catch (e) {
          AppLogger.info('❌ DioException: ${e.message}');
          AppLogger.info('❌ Response: ${e.response?.data}');
          DialogHelper.hideLoading();

          final responseData = e.response?.data;
          String errorMessage = 'ระบบขัดข้อง กรุณาลองใหม่';

          if (responseData is Map) {
            errorMessage =
                responseData['message']?.toString() ??
                responseData['error']?.toString() ??
                errorMessage;
          }

          DialogHelper.showNotification(
            title: 'เกิดข้อผิดพลาด',
            message: errorMessage,
            type: NotificationType.error,
          );
        } catch (e, stack) {
          AppLogger.info('❌ Error: $e');
          AppLogger.info('❌ Stack: $stack');
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
          color: AppColors.primaryPalette[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              controller.mode.value == CreatePostMode.edit ? 'บันทึก' : 'โพสต์',
              style: TextStyle(color: AppColors.primaryPalette[900]),
            ),
            const SizedBox(width: 6),
            Icon(LinkLianIcon.post, size: 16, color: AppColors.primaryPalette[900]),
          ],
        ),
      ),
    );
  }
}

class _DiscardDialogContent extends StatelessWidget {
  final String title;
  final String description;
  final String cancelText;
  final String confirmText;

  const _DiscardDialogContent({
    required this.title,
    required this.description,
    required this.cancelText,
    required this.confirmText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryPalette[700],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
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
                    elevation: 0,
                  ),
                  child: Text(
                    cancelText,
                    style: const TextStyle(
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
                    elevation: 0,
                  ),
                  child: Text(
                    confirmText,
                    style: const TextStyle(
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
    );
  }
}

Future<bool?> _showDiscardCreateDialog() {
  return Get.dialog<bool>(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.primaryPalette[300],
      child: const _DiscardDialogContent(
        title: 'ยกเลิกการสร้างโพสต์?',
        description:
            'คุณได้พิมพ์ข้อความหรือแนบไฟล์แล้ว\nหากยกเลิกข้อมูลทั้งหมดจะหายไป',
        cancelText: 'โพสต์ต่อ',
        confirmText: 'ยกเลิกโพสต์',
      ),
    ),
    barrierDismissible: false,
  );
}
