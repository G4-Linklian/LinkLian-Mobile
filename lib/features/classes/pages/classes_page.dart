import 'package:LinkLian/config/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/utils/dialog_helper.dart';
import '../controllers/class_feed_controller.dart';
import '../widgets/class_card.dart';
import '../widgets/semester_selector.dart';

class ClassesPage extends StatelessWidget {
  const ClassesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ClassFeedController>();
    final scrollController = ScrollController();

    // Setup infinite scroll
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        controller.fetchClassFeed(loadMore: true);
      }
    });

    return Scaffold(
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  await controller.refreshFeed();
                  DialogHelper.showNotification(
                    title: 'ห้องเรียนถูกโหลดแล้ว',
                    message: 'ข้อมูลห้องเรียนได้รับการอัปเดตแล้ว',
                    type: NotificationType.success,
                    titleSize: 24.0,
                  );
                },
                child: Padding(
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
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 200),
                                  Center(child: Text('ไม่มีห้องเรียน')),
                                ],
                              )
                            : ListView.builder(
                                controller: scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: controller.classList.length +
                                    (controller.isLoadingMore.value ? 1 : 0),
                                itemBuilder: (context, index) {
                                  // Loading indicator at bottom
                                  if (index >= controller.classList.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  final c = controller.classList[index];
                                  return ClassCard(
                                    data: c,
                                    roleName: controller.roleName,
                                    onTap: () {
                                      Get.toNamed(
                                        AppRoutes.classDetail,
                                        arguments: {
                                          'sectionId': c.sectionId,
                                          'subjectName': c.subjectNameTh,
                                          'className': c.effectiveClassName,
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}