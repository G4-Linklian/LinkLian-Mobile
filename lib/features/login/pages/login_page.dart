import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/login_bottom_sheet.dart';
import '../widgets/role_card.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/constants/linklian-icon.dart';
import '../../../core/constants/logo.dart';
import '../../../core/constants/strings.dart';
import '../controllers/login_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  void _openLoginSheet(BuildContext context, LoginController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (_) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            color: Colors.transparent,
            alignment: Alignment.bottomCenter,
            child: LoginBottomSheet(controller: controller),
          ),
        );
      },
    ).then((_) {
      controller.showEmailInfo.value = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController(), permanent: false);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: const BoxDecoration(

          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFFFF0E0), 
            ],
            stops: [0.5, 1.0],
          ),
          // image: DecorationImage(
          //   image: AssetImage('assets/images/wave_bg.png'),
          //   fit: BoxFit.cover,
          //   alignment: Alignment.topCenter,
          // ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              const SizedBox(height: 60),

               Image.asset(LinkLianLogos.bannerBlack, height: 56),

              const SizedBox(height: 16),

              const Text(
                'เลือกบทบาทเพื่อเข้าสู่ระบบ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6C2D13), 
                ),
              ),

              const SizedBox(height: AppSizes.xxxl),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: RoleCard(
                  icon: Icon(
                    LinkLianIcon.student,
                    size: 128,
                    color: AppColors.black,
                  ),

                  title: AppStrings.titleStudent,
                  onTap: () {
                    controller.selectedUserGroup.value = 'student';
                    _openLoginSheet(context, controller);
                  },
                ),
              ),

              const SizedBox(height: AppSizes.xxxl),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: RoleCard(
                  icon: Icon(
                    LinkLianIcon.teacher,
                    size: 128,
                    color: AppColors.black,
                  ),

                  title: AppStrings.titleTeacher,
                  onTap: () {
                    controller.selectedUserGroup.value = 'teacher';
                    _openLoginSheet(context, controller);
                  },
                ),
              ),
              
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}