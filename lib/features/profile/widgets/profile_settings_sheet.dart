import 'package:LinkLian/core/constants/colors.dart';
import 'package:LinkLian/core/constants/linklian-icon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/controller/auth_controller.dart';
import '../../profile/pages/account_page.dart';

class SettingsBottomSheetWithIcon extends StatelessWidget {
  const SettingsBottomSheetWithIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Bottom Sheet
        Padding(
          padding: const EdgeInsets.only(top: 30),
          child: const SettingsBottomSheet(),
        ),

        Positioned(
          top: 0,
          left: 24,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryPalette[500],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPalette[500]!.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              LinkLianIcon.settings,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ],
    );
  }
}

class SettingsBottomSheet extends StatelessWidget {
  const SettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 20, bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                'ตั้งค่า',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 16),

          _SettingItem(
            icon: LinkLianIcon.account,
            title: 'บัญชี',
            onTap: () async {
              final result = await Get.to(() => const AccountPage());

              if (result == true && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),

          const Divider(indent: 16, endIndent: 16),

          _SettingItem(
            icon: LinkLianIcon.security,
            title: 'พาสเวิร์ดและความปลอดภัย',
            onTap: () {},
          ),

          const Divider(indent: 16, endIndent: 16),

          _SettingItem(
            icon: LinkLianIcon.privacy,
            title: 'ข้อปฏิบัติส่วนบุคคล',
            onTap: () {},
          ),

          const Divider(indent: 16, endIndent: 16),

          _SettingItem(
            icon: LinkLianIcon.logout,
            title: 'ออกจากระบบ',
            isDanger: true,
            onTap: () async {
              Navigator.pop(context);
              await Get.find<AuthController>().logout();
            },
          ),

          const SizedBox(height: 20),

          const Text(
            'เวอร์ชัน 0.0.0',
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDanger;

  const _SettingItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: isDanger
            ? AppColors.dangerPalette[100]
            : AppColors.primaryPalette[100],
        child: Icon(
          icon,
          size: 24,
          weight: 600,
          color: isDanger
              ? AppColors.dangerPalette[500]
              : AppColors.primaryPalette[700],
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDanger ? AppColors.dangerPalette[500] : AppColors.black,
        ),
      ),
      onTap: onTap,
    );
  }
}
