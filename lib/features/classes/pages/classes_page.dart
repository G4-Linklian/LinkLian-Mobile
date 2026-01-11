import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/sizes.dart';
import '../controllers/class_feed_controller.dart';
import '../widgets/class_card.dart';
import '../widgets/semester_selector.dart';
import '../../../data/repository/fake_class_feed_repository.dart';
import '../../../data/repository/fake_semester_repository.dart';

class ClassesPage extends StatelessWidget {
  const ClassesPage({super.key});

  @override
  Widget build(BuildContext context) {

    final controller = Get.put(
      ClassFeedController(
        classFeedRepository: FakeClassFeedRepository(),
        semesterRepository: FakeSemesterRepository(),
        instId: 10,
        roleName: 'high school student',
      ),
);
    // final controller = Get.find<ClassFeedController>();

    return Scaffold(
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'ห้องเรียนของคุณ',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SemesterSelector(),

                        // ElevatedButton.icon(
                        //   onPressed: () {
                        //     // Add new room
                        //     controller.addRoom({
                        //       'name':
                        //           'ห้องใหม่ ${controller.roomsList.length + 1}',
                        //       'type': 'ห้องประชุม',
                        //       'capacity': 10,
                        //     });
                        //   },
                        //   icon: const Icon(Icons.add),
                        //   label: const Text('เพิ่มห้อง'),
                        // ),
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
                                  roleName: controller.roleName, // ⭐ เพิ่มบรรทัดนี้
                                  onTap: () {
                                    // TODO: ไปหน้า Feed ใน Class นั้นๆ
                                  },
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
