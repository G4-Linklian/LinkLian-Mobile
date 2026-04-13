import 'dart:io';

import 'package:LinkLian/core/constants/colors.dart';
import 'package:LinkLian/core/constants/linklian-icon.dart';
import 'package:LinkLian/core/utils/dialog_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/profile_controller.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final ProfileController _controller = Get.find<ProfileController>();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _detailCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _detailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      await _controller.pickReportImagesFromGallery();
    } catch (e) {
      DialogHelper.showNotification(
        title: 'เกิดข้อผิดพลาด',
        message: e.toString(),
        type: NotificationType.error,
      );
    }
  }

  Future<void> _submit() async {
    try {
      await _controller.submitInstitutionReport(
        title: _titleCtrl.text,
        detail: _detailCtrl.text,
      );

      _titleCtrl.clear();
      _detailCtrl.clear();

      if (!mounted) return;
      Get.back(result: true);

      DialogHelper.showNotification(
        title: 'ส่งรายงานสำเร็จ',
        message: 'ทีมงานได้รับข้อมูลของคุณแล้ว',
        type: NotificationType.success,
      );
    } catch (e) {
      DialogHelper.showNotification(
        title: 'ส่งรายงานไม่สำเร็จ',
        message: e.toString(),
        type: NotificationType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(LinkLianIcon.chevronleft, color: AppColors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'แจ้งปัญหา',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Obx(
          () => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _buildLabel('หัวข้อ', required: true),
              const SizedBox(height: 8),
              TextField(
                controller: _titleCtrl,
                maxLength: 120,
                decoration: _inputDecoration(hint: 'ระบุหัวข้อปัญหา'),
              ),
              const SizedBox(height: 10),
              _buildLabel('รายละเอียด', required: true),
              const SizedBox(height: 8),
              TextField(
                controller: _detailCtrl,
                maxLines: 4,
                minLines: 4,
                maxLength: 1000,
                decoration: _inputDecoration(hint: 'อธิบายปัญหาที่พบ'),
              ),
              const SizedBox(height: 8),
              const Text(
                'ไฟล์แนบ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryPalette[100],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primaryPalette[300]!,
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'อัปโหลดรูปภาพ',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryPalette[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'รองรับ JPG, PNG, WEBP และไฟล์รูปภาพอื่นๆ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _controller.reportImages.length >=
                                  ProfileController.maxReportImages
                              ? null
                              : _pickImages,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryPalette[200],
                            foregroundColor: AppColors.primaryPalette[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(LinkLianIcon.photo, size: 18),
                          label: const Text('เลือกรูป'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'เลือกแล้ว ${_controller.reportImages.length}/${ProfileController.maxReportImages} รูป',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_controller.reportImages.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 84,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _controller.reportImages.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final file = _controller.reportImages[index];
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    File(file.path),
                                    width: 84,
                                    height: 84,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () =>
                                        _controller.removeReportImageAt(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.5,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        LinkLianIcon.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _controller.reporting.value ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryPalette[600],
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _controller.reporting.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'ส่งรายงาน',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        children: [
          TextSpan(text: text),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38),
      filled: true,
      fillColor: Colors.grey.shade50,
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.primaryPalette[500]!, width: 1),
      ),
    );
  }
}
