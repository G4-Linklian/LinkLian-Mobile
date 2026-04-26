import 'package:LinkLian/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../../../../core/utils/file_picker_helper.dart';
import '../../../../core/constants/linklian-icon.dart';

import '../../../auth/controller/auth_controller.dart';
import '../controllers/class_feed_controller.dart';
import '../controllers/create_post_controller.dart';
import '../controllers/class_detail_controller.dart';
import '../widgets/class_selector.dart';
import '../widgets/attachment_file.dart';
import '../widgets/attachment_picture.dart';
import '../../../assignment/presentation/controllers/class_assignment_controller.dart';
import '../../../layout/controllers/navigation_controller.dart';
import '../../../../config/app_routes.dart';

class CreatePostClassPage extends StatefulWidget {
  const CreatePostClassPage({super.key});

  @override
  State<CreatePostClassPage> createState() => _CreatePostClassPageState();
}

class _CreatePostClassPageState extends State<CreatePostClassPage> {
  DateTime? _lastPostTapAt;

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

  Future<void> _handleClose(CreatePostController controller) async {
    switch (controller.closeAction) {
      case ClosePostAction.closeImmediately:
        Get.back();
        return;
      case ClosePostAction.confirmDiscardEdit:
        final shouldClose = await _showDiscardEditDialog();
        if (shouldClose == true) Get.back();
        return;
      case ClosePostAction.confirmDiscardCreate:
        final shouldClose = await _showDiscardCreateDialog();
        if (shouldClose == true) Get.back();
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

    return PopScope(
      canPop: !controller.hasContent,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (controller.hasContent) {
          await _handleClose(controller);
        } else {
          Get.back();
        }
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: ClassSelector(
                      controller: controller,
                      classFeedController: classFeedController,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Obx(() {
                    final isEditMode =
                        controller.mode.value == CreatePostMode.edit;
                    final isPostTypeLocked = controller.isPostTypeLocked.value;

                    if (!isTeacher) {
                      return Opacity(
                        opacity: isEditMode ? 0.4 : 1.0,
                        child: _buildTagChip(
                          label: 'คำถาม',
                          isSelected: controller.postType.value == 'question',
                          onTap: isEditMode
                              ? () {}
                              : () => controller.postType.value = 'question',
                        ),
                      );
                    }

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
                                : () =>
                                      controller.postType.value = 'assignment',
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
                                : () => controller.postType.value =
                                      'announcement',
                          ),
                        ),
                      ],
                    );
                    }),
                  ),
                ],
              ),
            ),

            // ROW 2: Assignment Type Dropdown
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
                      _buildAssignmentTypeChip(controller),
                    ],
                  ),
                );
              }),

            // ROW 3: Due date display
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
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(AppSizes.md),
                        child: isTeacher
                            ? _buildTeacherContent(controller)
                            : _buildStudentContent(controller),
                      ),
                    ),
                    Obx(() {
                      if (controller.attachments.isEmpty) {
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
                    if (isTeacher)
                      Obx(() {
                        if (controller.postType.value != 'assignment') {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
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
                          onPressed: () => _showLinkDialog(context, controller),
                        ),
                        const Spacer(),
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

  Widget _buildStudentContent(CreatePostController controller) {
    return TextField(
      controller: _contentController,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      style: const TextStyle(fontSize: 16),
      decoration: const InputDecoration(
        hintText: 'มีคำถามจะถามใช่ไหม...',
        hintStyle: TextStyle(color: AppColors.gray, fontSize: 16),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildTeacherContent(CreatePostController controller) {
    return Obx(() {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              maxLines: 1,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: controller.postType.value == 'assignment'
                    ? 'ชื่อการบ้าน'
                    : 'ชื่อประกาศ',
                hintStyle: TextStyle(
                  color: AppColors.gray.withValues(alpha: 0.6),
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

  Future<void> _showDateTimePicker(
    BuildContext context,
    CreatePostController controller,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentDue = controller.dueDate.value;
    final dueDateOnly = currentDue == null
        ? null
        : DateTime(currentDue.year, currentDue.month, currentDue.day);

    // Allow opening picker in edit mode even if existing due date is in the past.
    final firstDate = (dueDateOnly != null && dueDateOnly.isBefore(today))
        ? dueDateOnly
        : today;
    final lastDate = DateTime(now.year + 1, now.month, now.day);

    DateTime initialDate = dueDateOnly ?? today.add(const Duration(days: 7));
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
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

    controller.dueDate.value = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  Widget _buildAssignmentTypeChip(CreatePostController controller) {
    return Obx(() {
      if (controller.isCheckingSubmissionStatus.value) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.buttonPalette[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.buttonPalette[300]!, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.buttonPalette[700],
                ),
              ),
              const SizedBox(width: 8),
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
        );
      }

      if (!controller.canChangeAssignmentType) {
        return GestureDetector(
          onLongPress: () {
            DialogHelper.showNotification(
              title: 'ไม่สามารถเปลี่ยนประเภทงาน',
              message: controller.assignmentTypeLockReason,
              type: NotificationType.warning,
            );
          },
          child: Opacity(
            opacity: 0.45,
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
                  const SizedBox(width: 4),
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: AppColors.buttonPalette[700],
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return PopupMenuButton<bool>(
        onSelected: (isGroup) => controller.setAssignmentIsGroup(isGroup),
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
              : AppColors.gray.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.buttonPalette[300]!
                : AppColors.gray.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.buttonPalette[700]
                : AppColors.black.withValues(alpha: 0.5),
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
                      color: AppColors.black.withValues(alpha: 0.1),
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

  void _showLinkDialog(BuildContext context, CreatePostController controller) {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        final url = urlController.text.trim();
                        if (url.isEmpty) return;
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
                        controller.attachments.add({
                          'file_type': 'link',
                          'file_url': url,
                          'file_name': url,
                          'original_name': url,
                          'file_size': 0,
                        });
                        Navigator.pop(ctx);
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
    final auth = Get.find<AuthController>();

    return Obx(() {
      final isSubmitting = controller.isLoading.value;

      return GestureDetector(
        onTap: isSubmitting
            ? null
            : () async {
                final now = DateTime.now();
                if (_lastPostTapAt != null &&
                    now.difference(_lastPostTapAt!) <
                        const Duration(milliseconds: 700)) {
                  return;
                }
                _lastPostTapAt = now;

                if (controller.isLoading.value) return;
                // ===== VALIDATION =====
                if (controller.postType.value.isEmpty) {
                  DialogHelper.showErrorDialog(
                    description: 'กรุณาเลือกประเภทโพสต์',
                  );
                  return;
                }
                if (!controller.isAllSelected &&
                    controller.selectedSectionIds.isEmpty) {
                  DialogHelper.showErrorDialog(
                    description: 'กรุณาเลือกอย่างน้อย 1 คลาส',
                  );
                  return;
                }
                if (isTeacher && controller.title.value.trim().isEmpty) {
                  DialogHelper.showErrorDialog(
                    description: 'กรุณากรอกชื่อโพสต์',
                  );
                  return;
                }
                if (controller.content.value.trim().isEmpty) {
                  DialogHelper.showErrorDialog(
                    description: 'กรุณากรอกเนื้อหาโพสต์',
                  );
                  return;
                }
                if (controller.postType.value == 'assignment' &&
                    controller.dueDate.value == null) {
                  DialogHelper.showErrorDialog(
                    description: 'กรุณาเลือกวันกำหนดส่ง',
                  );
                  return;
                }

                // ===== SUBMIT =====
                try {
                  DialogHelper.showLoading('กำลังโพสต์...');
                  final res = await controller.submitPost();
                  if (res['ignored'] == true) {
                    DialogHelper.hideLoading();
                    return;
                  }
                  DialogHelper.hideLoading();

                  final isSuccess =
                      res['success'] == true ||
                      res['data'] != null ||
                      res['post_content_id'] != null;

                  if (!isSuccess) {
                    DialogHelper.showNotification(
                      title: 'เกิดข้อผิดพลาด',
                      message:
                          res['error']?['message'] ?? 'ไม่สามารถสร้างโพสต์ได้',
                      type: NotificationType.error,
                    );
                    return;
                  }

                  appLog.info('[CreatePost Class page] Starting redirect');
                  appLog.info(
                    '[CreatePost Class page] Source',
                    data: {controller.source},
                  );
                  appLog.info(
                    '[CreatePost Class page] Mode',
                    data: {controller.mode.value},
                  );
                  appLog.info(
                    '[CreatePost Class page] Selected sections',
                    data: {controller.selectedSectionIds},
                  );

                  // ===== REDIRECT BASED ON SOURCE AND MODE =====

                  // EDIT MODE
                  if (controller.mode.value == CreatePostMode.edit) {
                    controller.markCurrentStateAsSaved();
                    appLog.info(
                      '[CreatePost Class page] Edit mode: Going back',
                    );
                    Get.back(result: {
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
                    return;
                  }

                  final hasWarning =
                      res['warning'] != null &&
                      (res['warning'] as List).isNotEmpty;
                  final successMessage = hasWarning
                      ? res['warning'][0]['message'].toString()
                      : 'ระบบได้บันทึกโพสต์ของคุณเรียบร้อยแล้ว';
                  final successType = hasWarning
                      ? NotificationType.warning
                      : NotificationType.success;
                  controller.clearDraftState();

                  // FROM CLASS ASSIGNMENT PAGE
                  if (controller.source == CreatePostSource.classAssignment) {
                    appLog.info(
                      '[CreatePost Class page] From classAssignment: pop + refresh',
                    );
                    Get.back(result: {'success': true, 'refresh': true});
                    await Future.delayed(const Duration(milliseconds: 200));
                    DialogHelper.showNotification(
                      title: 'โพสต์สำเร็จ',
                      message: successMessage,
                      type: successType,
                    );
                    if (Get.isRegistered<ClassAssignmentController>()) {
                      Get.find<ClassAssignmentController>()
                          .refreshAssignments();
                    }
                    return;
                  }

                  // FROM CLASS DETAIL PAGE
                  if (controller.source == CreatePostSource.classDetail) {
                    appLog.info(
                      '[CreatePost Class page] From classDetail: pop + refresh',
                    );
                    Get.back(result: {'success': true, 'refresh': true});
                    await Future.delayed(const Duration(milliseconds: 200));
                    DialogHelper.showNotification(
                      title: 'โพสต์สำเร็จ',
                      message: successMessage,
                      type: successType,
                    );
                    if (Get.isRegistered<ClassDetailController>()) {
                      final detailController =
                          Get.find<ClassDetailController>();
                      await detailController.fetchPosts();
                      detailController.scrollToTop();
                    }
                    return;
                  }

                  // FROM CLASS FEED (ClassesPage) - single class → ไป ClassDetail
                  if (controller.source == CreatePostSource.classFeed &&
                      controller.selectedSectionIds.length == 1) {
                    final sectionId = controller.selectedSectionIds.first;
                    final classFeedCtrl = Get.find<ClassFeedController>();
                    final found = classFeedCtrl.classList.firstWhereOrNull(
                      (c) => c.sectionId == sectionId,
                    );
                    final subjectName = found?.subjectNameTh ?? '';
                    final className = found?.effectiveClassName ?? '';

                    appLog.info(
                      '[CreatePost Class page] classFeed single class → Close then ClassDetail',
                    );

                    final detailArgs = {
                      'sectionId': sectionId,
                      'subjectName': subjectName,
                      'className': className,
                    };

                    final navController = Get.find<NavigationController>();
                    navController.showClassDetailFromRedirect(detailArgs);
                    Get.back();
                    await Future.delayed(const Duration(milliseconds: 200));
                    DialogHelper.showNotification(
                      title: 'โพสต์สำเร็จ',
                      message: successMessage,
                      type: successType,
                    );
                    return;
                  }

                  // FROM ASSIGNMENT FEED (AssignmentPage) - single class → ไป ClassAssignment
                  if (controller.source == CreatePostSource.assignmentFeed &&
                      controller.selectedSectionIds.length == 1) {
                    final sectionId = controller.selectedSectionIds.first;
                    final classFeedCtrl = Get.find<ClassFeedController>();
                    final found = classFeedCtrl.classList.firstWhereOrNull(
                      (c) => c.sectionId == sectionId,
                    );
                    final subjectName = found?.subjectNameTh ?? '';
                    final className = found?.effectiveClassName ?? '';

                    appLog.info(
                      '[CreatePost Class page] assignmentFeed single class → ClassAssignment',
                    );

                    Get.back();
                    await Future.delayed(const Duration(milliseconds: 300));

                    Get.offNamed(
                      AppRoutes.classAssignment,
                      arguments: {
                        'sectionId': sectionId,
                        'className': className,
                        'subjectName': subjectName,
                        'role': auth.roleName.value,
                      },
                    );
                    await Future.delayed(const Duration(milliseconds: 200));
                    DialogHelper.showNotification(
                      title: 'โพสต์สำเร็จ',
                      message: successMessage,
                      type: successType,
                    );

                    return;
                  }

                  // MULTIPLE CLASSES or ALL → back to feed + refresh
                  appLog.info(
                    '[CreatePost Class page] Multiple/all classes: back to feed',
                  );
                  Get.back(result: {'success': true, 'refresh': true});
                  await Future.delayed(const Duration(milliseconds: 200));
                  DialogHelper.showNotification(
                    title: 'โพสต์สำเร็จ',
                    message: successMessage,
                    type: successType,
                  );
                  if (Get.isRegistered<ClassFeedController>()) {
                    Get.find<ClassFeedController>().refreshFeed();
                  }
                } on DioException catch (e) {
                  appLog.info(
                    '[CreatePost Class page] DioException: ${e.message}',
                  );
                  DialogHelper.hideLoading();
                  final responseData = e.response?.data;
                  String errorMsg = 'ระบบขัดข้อง กรุณาลองใหม่';
                  if (responseData is Map) {
                    errorMsg =
                        responseData['message']?.toString() ??
                        responseData['error']?.toString() ??
                        errorMsg;
                  }
                  DialogHelper.showNotification(
                    title: 'เกิดข้อผิดพลาด',
                    message: errorMsg,
                    type: NotificationType.error,
                  );
                } catch (e, stack) {
                  appLog.info('[CreatePost Class page] Error: $e\n$stack');
                  DialogHelper.hideLoading();
                  DialogHelper.showNotification(
                    title: 'เกิดข้อผิดพลาด',
                    message: 'ไม่สามารถสร้างโพสต์ได้: $e',
                    type: NotificationType.error,
                  );
                }
              },
        child: Opacity(
          opacity: isSubmitting ? 0.7 : 1,
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
                  isSubmitting
                      ? 'กำลังโพสต์...'
                      : (controller.mode.value == CreatePostMode.edit
                            ? 'บันทึก'
                            : 'โพสต์'),
                  style: TextStyle(color: AppColors.primaryPalette[900]),
                ),
                const SizedBox(width: 6),
                if (isSubmitting)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryPalette[900],
                    ),
                  )
                else
                  Icon(
                    LinkLianIcon.post,
                    size: 16,
                    color: AppColors.primaryPalette[900],
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ===== DIALOG WIDGETS =====

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
