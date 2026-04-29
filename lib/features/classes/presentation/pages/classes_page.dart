import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../controllers/class_feed_controller.dart';
import '../widgets/class_card.dart';
import '../widgets/semester_selector.dart';
import '../../../layout/controllers/navigation_controller.dart';

class ClassesPage extends StatefulWidget {
  const ClassesPage({super.key});

  @override
  State<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  late final ScrollController scrollController;
  late final ClassFeedController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ClassFeedController>();
    scrollController = ScrollController();

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        controller.fetchClassFeed(loadMore: true);
      }
    });

    // Note: Class detail restoration is handled by MainPage (layout.dart)
    // to ensure instant transition without showing ClassesPage first
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header — always visible
            Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        controller.isLoading.value
                            ? 'กำลังโหลด...'
                            : 'ห้องเรียนของคุณ',
                        key: ValueKey(controller.isLoading.value),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SemesterSelector(),
                  ],
                )),
            const SizedBox(height: 16),

            // List area — animated switch between skeleton and content
            Expanded(
              child: Obx(() {
                final isLoading = controller.isLoading.value;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: isLoading
                      ? ListView.builder(
                          key: const ValueKey('skeleton'),
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 4,
                          itemBuilder: (_, index) => const ClassCardSkeleton(),
                        )
                      : RefreshIndicator(
                          key: const ValueKey('content'),
                          onRefresh: () async {
                            await controller.refreshFeed();
                            DialogHelper.showNotification(
                              title: 'ห้องเรียนถูกโหลดแล้ว',
                              message: 'ข้อมูลห้องเรียนได้รับการอัปเดตแล้ว',
                              type: NotificationType.success,
                              titleSize: 24.0,
                            );
                          },
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
                                        final navController =
                                            Get.find<NavigationController>();
                                        navController.showClassDetail({
                                          'sectionId': c.sectionId,
                                          'subjectName': c.subjectNameTh,
                                          'className': c.effectiveClassName,
                                        });
                                      },
                                    );
                                  },
                                ),
                        ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
