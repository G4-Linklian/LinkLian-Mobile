import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:linklian/core/constants/colors.dart';
import '../controllers/assignment_controller.dart';
import '../widgets/home_widgets.dart';
import '../../../core/constants/sizes.dart';

class AssignmentPage extends StatelessWidget {
  const AssignmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    
    return Scaffold(
      body: Obx(() => controller.isLoading.value 
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
                    // backgroundColor: AppColors.black,
                  ),
                ),
                const SizedBox(height: 16),
                // Expanded(
                //   child: ListView(
                //     children: [
                //       HomeCard(
                //         title: 'เติมเงินออนไลน์',
                //         onTap: () {
                //           // Navigate to online payment
                //         },
                //       ),
                //       HomeCard(
                //         title: 'เติมเงินผ่านตู้ ATM',
                //         onTap: () {
                //           // Navigate to ATM payment
                //         },
                //       ),
                //       HomeCard(
                //         title: 'เติมเงินผ่านร้านสะดวกซื้อ',
                //         onTap: () {
                //           // Navigate to convenience store payment
                //         },
                //       ),
                //       HomeCard(
                //         title: 'ประวัติการเติมเงิน',
                //         onTap: () {
                //           // Navigate to payment history
                //         },
                //       ),
                //     ],
                //   ),
                // ),
              ],
            ),
          ),
      ),
    );
  }
}