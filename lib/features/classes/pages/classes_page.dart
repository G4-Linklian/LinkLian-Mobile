import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/sizes.dart';
import '../controllers/class_feed_controller.dart';
import '../widgets/class_card.dart';
import '../widgets/semester_selector.dart';
import '../../auth/controller/auth_controller.dart';

 class ClassesPage extends StatelessWidget {
  const ClassesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ClassFeedController>();

    return Scaffold(
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ห้องเรียนของคุณ',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SemesterSelector(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: controller.classList.isEmpty
                          ? const Center(child: Text('ไม่มีห้องเรียน'))
                          : ListView.builder(
                              itemCount: controller.classList.length,
                              itemBuilder: (context, index) {
                                final c = controller.classList[index];
                                return ClassCard(
                                  data: c,
                                  roleName: controller.roleName, 
                                  onTap: () {},
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}