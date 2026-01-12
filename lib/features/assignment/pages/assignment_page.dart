import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:linklian/core/constants/colors.dart';
import '../controllers/assignment_controller.dart';
// import '../widgets/home_widgets.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/constants/colors.dart';
// import '../../../core/utils/logger.dart';
import '../../auth/controller/auth_controller.dart';

class AssignmentPage extends StatelessWidget {
  const AssignmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    // ⭐ guard เหมือน ClassesPage
    if (auth.roleName.value == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final controller = Get.put(AssignmentController(), tag: 'assignment');

    return Scaffold(
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'การบ้าน',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),

                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successPalette[600],
                          foregroundColor: AppColors.white,
                        ),
                        onPressed: () {
                          // DialogHelper.showErrorDialog(
                          //   title: "ผิดพลาด",
                          //   description: "รหัสผ่านไม่ถูกต้อง",
                          // );

                          // DialogHelper.showLoading("กำลังโหลดข้อมูล...");

                          DialogHelper.showNotification(
                            title: "สร้างโพสต์สำเร็จ",
                            message: null,
                            type: NotificationType.success,
                          );

                          // DialogHelper.hideLoading();
                        },
                        child: const Text("ทดสอบแจ้งเตือน Success"),
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warningPalette[500],
                          foregroundColor: AppColors.white,
                        ),
                        onPressed: () {
                          DialogHelper.showNotification(
                            title: "ไฟล์แนบเสียหาย",
                            message: null,
                            type: NotificationType.warning,
                          );
                        },
                        child: const Text("ทดสอบแจ้งเตือน Warning"),
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.dangerPalette[400],
                          foregroundColor: AppColors.white,
                        ),
                        onPressed: () {
                          DialogHelper.showNotification(
                            title: "โพสต์ไม่สำเร็จ",
                            message: "ไฟล์รูปภาพมีขนาดใหญ่เกินไป",
                            type: NotificationType.error,
                          );
                        },
                        child: const Text("ทดสอบแจ้งเตือน Error"),
                      ),
                    ),

                    // -----------------------
                    const SizedBox(height: AppSizes.md),
                    ElevatedButton(
                      onPressed: () {
                        controller.fetchRole(flagValid: false);
                      },
                      child: const Text("ดึงข้อมูล Role"),
                    ),
                    // const SizedBox(height: AppSizes.md),
                    // ElevatedButton(
                    //   onPressed: () {
                    //     controller.createRole("Admin", "Full Access", {}, true, DateTime.now(), DateTime.now());
                    //   },
                    //   child: const Text("สร้าง Role ใหม่"),
                    // ),
                    Obx(() {
                      final roles = controller.roles;

                      if (roles.isEmpty) {
                        return const Text('ยังไม่มีข้อมูล Role');
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: roles.map((role) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ID: ${role.roleId}'),
                                  Text('Name: ${role.roleName}'),
                                  Text('Type: ${role.roleType}'),
                                  Text('Valid: ${role.flagValid}'),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }),

                    const SizedBox(height: AppSizes.md),
                    ElevatedButton(
                      onPressed: () {
                        controller.updateRole(roleId: 1, flagValid: true);
                      },
                      child: const Text("อัปเดต Role"),
                    ),

                    // ================= LOG OUT =================
                    const SizedBox(height: AppSizes.xl),

                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.dangerPalette[500],
                          foregroundColor: AppColors.white,
                        ),
                        onPressed: () async {
                          await Get.find<AuthController>().logout();
                        },
                        child: const Text('Log out'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
