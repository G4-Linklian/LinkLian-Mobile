import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());
    
    return Scaffold(
      body: Obx(() => controller.isLoading.value 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            // child: Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: [
            //     const Text(
            //       'โปรไฟล์',
            //       style: TextStyle(
            //         fontSize: 24,
            //         fontWeight: FontWeight.bold,
            //       ),
            //     ),
            //     const SizedBox(height: 16),
            //     ProfileHeader(
            //       name: controller.userName.value.isEmpty ? 'ผู้ใช้' : controller.userName.value,
            //       email: controller.userEmail.value.isEmpty ? 'user@example.com' : controller.userEmail.value,
            //       imageUrl: controller.userImage.value.isEmpty ? null : controller.userImage.value,
            //       onEditTap: () {
            //         // Navigate to edit profile
            //       },
            //     ),
            //     const SizedBox(height: 16),
            //     Expanded(
            //       child: ListView(
            //         children: [
            //           ProfileMenuItem(
            //             icon: Icons.person,
            //             title: 'แก้ไขข้อมูลส่วนตัว',
            //             subtitle: 'เปลี่ยนชื่อ อีเมล หรือรูปภาพ',
            //             onTap: () {
            //               // Navigate to edit profile
            //             },
            //           ),
            //           ProfileMenuItem(
            //             icon: Icons.security,
            //             title: 'เปลี่ยนรหัสผ่าน',
            //             subtitle: 'อัพเดทรหัสผ่านของคุณ',
            //             onTap: () {
            //               // Navigate to change password
            //             },
            //           ),
            //           ProfileMenuItem(
            //             icon: Icons.notifications,
            //             title: 'การแจ้งเตือน',
            //             subtitle: 'ตั้งค่าการแจ้งเตือน',
            //             onTap: () {
            //               // Navigate to notifications settings
            //             },
            //           ),
            //           ProfileMenuItem(
            //             icon: Icons.help,
            //             title: 'ช่วยเหลือ',
            //             subtitle: 'คำถามที่พบบ่อย',
            //             onTap: () {
            //               // Navigate to help
            //             },
            //           ),
            //           ProfileMenuItem(
            //             icon: Icons.info,
            //             title: 'เกี่ยวกับแอป',
            //             subtitle: 'เวอร์ชัน 1.0.0',
            //             onTap: () {
            //               // Show about dialog
            //             },
            //           ),
            //           const SizedBox(height: 16),
            //           ElevatedButton.icon(
            //             onPressed: () {
            //               controller.logout();
            //             },
            //             icon: const Icon(Icons.logout),
            //             label: const Text('ออกจากระบบ'),
            //             style: ElevatedButton.styleFrom(
            //               backgroundColor: Colors.red,
            //               foregroundColor: Colors.white,
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ],
            // ),
          ),
      ),
    );
  }
}