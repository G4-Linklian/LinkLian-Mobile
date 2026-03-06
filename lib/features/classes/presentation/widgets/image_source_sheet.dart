import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/colors.dart';

class ImageSourceSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const ImageSourceSheet({
    super.key,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _item(icon: Icons.camera_alt, label: 'ถ่ายรูป', onTap: onCamera),
            _item(
              icon: Icons.photo_library,
              label: 'เลือกรูปจากคลัง',
              onTap: onGallery,
            ),
            const Divider(),
            _item(
              icon: Icons.close,
              label: 'ยกเลิก',
              isCancel: true,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isCancel = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isCancel ? AppColors.dangerPalette[500] : AppColors.primaryPalette[500],
      ),
      title: Text(label),
      onTap: () {
        Get.back();
        onTap();
      },
    );
  }
}
