import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/constants/colors.dart';
import '../../classes/controllers/class_feed_controller.dart';
import '../../classes/widgets/class_card.dart';
import '../../classes/widgets/semester_selector.dart';
import '../../../config/app_routes.dart';

class AssignmentPage extends StatefulWidget {
  const AssignmentPage({super.key});

  @override
  State<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends State<AssignmentPage> {
  late final ScrollController _scrollController;
  late final ClassFeedController classFeedController;

  @override
  void initState() {
    super.initState();
    classFeedController = Get.find<ClassFeedController>();
    _scrollController = ScrollController();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        classFeedController.fetchClassFeed(loadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Obx(() {
        if (classFeedController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          color: AppColors.primaryPalette[500],
          onRefresh: classFeedController.refreshFeed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'การบ้านของคุณ',
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
                  child: classFeedController.classList.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 200),
                            Center(child: Text('ไม่พบรายวิชา')),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          controller: _scrollController,
                          itemCount:
                              classFeedController.classList.length +
                              (classFeedController.isLoadingMore.value ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= classFeedController.classList.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final c = classFeedController.classList[index];
                            final roleName = classFeedController.roleName;
                            return ClassCard(
                              data: c,
                              roleName: roleName,
                              showStudentCount: false,
                              onTap: () {
                                Get.toNamed(
                                  AppRoutes.classAssignment,
                                  arguments: {
                                    'sectionId': c.sectionId,
                                    'className': c.effectiveClassName,
                                    'subjectName': c.subjectNameTh.isNotEmpty
                                        ? c.subjectNameTh
                                        : c.subjectNameEn,
                                    'role': roleName,
                                  },
                                  preventDuplicates: true,
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}