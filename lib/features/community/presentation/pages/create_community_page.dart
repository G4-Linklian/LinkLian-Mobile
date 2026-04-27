import 'package:LinkLian/core/constants/colors.dart';
import 'package:LinkLian/core/constants/linklian-icon.dart';
import 'package:LinkLian/core/utils/dialog_helper.dart';
import 'package:LinkLian/features/community/presentation/widgets/tag_selection_popup.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/create_community_controller.dart';

class CreateCommunityPage extends StatelessWidget {
  const CreateCommunityPage({super.key});

  Future<void> _handleClose(CreateCommunityController controller) async {
    final hasContent =
        controller.nameController.text.trim().isNotEmpty ||
        controller.descriptionController.text.trim().isNotEmpty ||
        controller.selectedImage.value != null ||
        controller.selectedTags.isNotEmpty ||
        controller.rules.isNotEmpty;

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
                "ยกเลิกการสร้างชุมชน?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryPalette[700],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "คุณได้กรอกข้อมูลบางส่วนแล้ว\nหากยกเลิกข้อมูลทั้งหมดจะหายไป",
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
                        "ยกเลิกโพสต์",
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

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CreateCommunityController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleClose(controller);
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: const SizedBox(),
          title: Obx(
            () => Text(
              controller.isEditMode.value ? "แก้ไขชุมชน" : "สร้างชุมชน",
              style: TextStyle(
                color: AppColors.black,
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: "ชื่อชุมชน ",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: "*",
                            style: TextStyle(
                              color: AppColors.primaryPalette[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.nameController,
                      minLines: 1,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: _inputDecoration("ระบุชื่อชุมชนของคุณ..."),
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      "รายละเอียด",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),

                    TextField(
                      controller: controller.descriptionController,
                      minLines: 1,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: _inputDecoration(
                        "อธิบายเกี่ยวกับชุมชนของคุณ...",
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text.rich(
                      TextSpan(
                        text: "รูปปกชุมชน ",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: "*",
                            style: TextStyle(
                              color: AppColors.primaryPalette[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppColors.primaryPalette[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "แนะนำรูปแนวนอน ",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryPalette[500],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Obx(
                      () => GestureDetector(
                        onTap: controller.pickImage,
                        child: Container(
                          height: 160,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: AppColors.primaryPalette[50],
                            border: Border.all(
                              color: AppColors.primaryPalette[200]!,
                              width: 1,
                            ),
                          ),

                          child: controller.selectedImage.value != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.file(
                                        controller.selectedImage.value!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),

                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: controller.pickImage,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color:
                                                AppColors.primaryPalette[200],
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors
                                                    .primaryPalette[800]!
                                                    .withValues(alpha: 0.7),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.edit,
                                            size: 18,
                                            color:
                                                AppColors.primaryPalette[700],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : controller.bannerUrl.value != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.network(
                                        controller.bannerUrl.value!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),

                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: controller.pickImage,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color:
                                                AppColors.primaryPalette[200],
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors
                                                    .primaryPalette[800]!
                                                    .withValues(alpha: 0.7),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.edit,
                                            size: 18,
                                            color:
                                                AppColors.primaryPalette[700],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 48,
                                        color: AppColors.primaryPalette[400],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "คลิกเพื่ออัปโหลดรูปภาพ",
                                        style: TextStyle(
                                          color: AppColors.primaryPalette[600],
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text.rich(
                      TextSpan(
                        text: "ประเภทชุมชน ",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: "*",
                            style: TextStyle(
                              color: AppColors.primaryPalette[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    Obx(
                      () => Row(
                        children: [
                          Expanded(
                            child: _privacyButton(
                              title: "กลุ่มสาธารณะ",
                              icon: Icons.public,
                              selected: !controller.isPrivate.value,
                              onTap: () => controller.isPrivate.value = false,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _privacyButton(
                              title: "กลุ่มส่วนตัว",
                              icon: Icons.lock,
                              selected: controller.isPrivate.value,
                              onTap: () => controller.isPrivate.value = true,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text.rich(
                          TextSpan(
                            text: "แท็ก ",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            children: [
                              TextSpan(
                                text: "*",
                                style: TextStyle(
                                  color: AppColors.primaryPalette[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) =>
                                  TagSelectionPopup(controller: controller),
                            );
                          },
                          icon: Icon(
                            Icons.add_circle_outline,
                            size: 18,
                            color: AppColors.primaryPalette[600],
                          ),
                          label: Text(
                            "เพิ่มแท็ก",
                            style: TextStyle(
                              color: AppColors.primaryPalette[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                        ),
                      ],
                    ),

                    Obx(
                      () => controller.selectedTags.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primaryPalette[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primaryPalette[100]!,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  "ยังไม่มีแท็ก",
                                  style: TextStyle(
                                    color: AppColors.primaryPalette[400],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: controller.selectedTags.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryPalette[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "#$tag",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryPalette[700],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () => controller.removeTag(tag),
                                        child: Icon(
                                          Icons.close,
                                          size: 16,
                                          color: AppColors.primaryPalette[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "กฎของชุมชน",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Obx(
                      () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...controller.rules.asMap().entries.map((entry) {
                            final index = entry.key;
                            final rule = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPalette[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primaryPalette[200]!,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryPalette[300],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          "${index + 1}",
                                          style: TextStyle(
                                            color:
                                                AppColors.primaryPalette[700],
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        rule,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => controller.removeRule(rule),
                                      child: Icon(
                                        Icons.close,
                                        size: 20,
                                        color: AppColors.dangerPalette[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          TextField(
                            controller: controller.ruleInputController,
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty) {
                                controller.addRule(value);
                              }
                            },
                            decoration: InputDecoration(
                              hintText: "พิมพ์กฎแล้วกด Enter เพื่อเพิ่ม...",
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: AppColors.white,
                              prefixIcon: Icon(
                                Icons.add_circle_outline,
                                color: AppColors.primaryPalette[400],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.primaryPalette[200]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.primaryPalette[200]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.primaryPalette[200]!,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border(
                  top: BorderSide(
                    color: AppColors.primaryPalette[100]!,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    const Spacer(),
                    _buildCreateButton(controller: controller),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),

      filled: true,
      fillColor: AppColors.white,

      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,

      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
    );
  }

  Widget _privacyButton({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryPalette[200]
              : AppColors.primaryPalette[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primaryPalette[300]!
                : AppColors.primaryPalette[200]!,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? AppColors.primaryPalette[700]
                  : AppColors.primaryPalette[600],
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: selected
                    ? AppColors.primaryPalette[700]
                    : AppColors.primaryPalette[600],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showIncompleteDialog() async {
    await Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.primaryPalette[300],
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.dangerPalette[500],
              ),
              const SizedBox(height: 16),
              Text(
                "ข้อมูลไม่ครบถ้วน",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryPalette[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "กรุณากรอกข้อมูลให้ครบถ้วน",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.primaryPalette[700],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPalette[500],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    "ตกลง",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildCreateButton({required CreateCommunityController controller}) {
    return Obx(
      () => GestureDetector(
        onTap: controller.isLoading.value
            ? null
            : () async {
                final isNameValid = controller.nameController.text
                    .trim()
                    .isNotEmpty;

                final isTagValid = controller.selectedTags.isNotEmpty;
                final isImageValid = controller.isEditMode.value
                    ? true
                    : controller.selectedImage.value != null;

                final isTypeValid = true;

                if (!isNameValid ||
                    !isTagValid ||
                    !isImageValid ||
                    !isTypeValid) {
                  await _showIncompleteDialog();
                  return;
                }

                try {
                  await controller.submitCommunity();

                  Get.back(result: true);

                  DialogHelper.showNotification(
                    title: controller.isEditMode.value
                        ? 'แก้ไขชุมชนสำเร็จ'
                        : 'สร้างชุมชนสำเร็จ',
                    message: controller.isEditMode.value
                        ? 'ชุมชนของคุณถูกอัปเดตแล้ว'
                        : 'ชุมชนของคุณถูกสร้างเรียบร้อยแล้ว',
                    type: NotificationType.success,
                  );
                } catch (e) {
                  DialogHelper.showNotification(
                    title: 'เกิดข้อผิดพลาด',
                    message: 'ไม่สามารถบันทึกข้อมูลได้',
                    type: NotificationType.error,
                  );
                }
              },

        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: controller.isLoading.value
                ? AppColors.primaryPalette[300]
                : AppColors.primaryPalette[500],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                controller.isEditMode.value ? "บันทึก" : "สร้าง",
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(LinkLianIcon.post, size: 18, color: AppColors.white),
            ],
          ),
        ),
      ),
    );
  }
}
