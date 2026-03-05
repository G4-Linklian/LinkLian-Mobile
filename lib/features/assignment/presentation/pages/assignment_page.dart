import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/constants/colors.dart';
import '../../../classes/presentation/controllers/class_feed_controller.dart';
import '../../../classes/presentation/widgets/class_card.dart';
import '../../../classes/presentation/widgets/semester_selector.dart';
import '../../../layout/controllers/navigation_controller.dart';

class AssignmentPage extends StatefulWidget {
  const AssignmentPage({super.key});

  @override
  State<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends State<AssignmentPage> {
  late final ScrollController _scrollController;
  late final ClassFeedController classFeedController;
  late final NavigationController _navController;

  @override
  void initState() {
    super.initState();
    classFeedController = Get.find<ClassFeedController>();
    _navController = Get.find<NavigationController>();
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

  void _openClassAssignment(Map<String, dynamic> args) {
    _navController.showClassAssignment(args);
  }

  @override
  Widget build(BuildContext context) {
    return _AssignmentFeedBody(
      key: const ValueKey('assignmentFeedBody'),
      scrollController: _scrollController,
      classFeedController: classFeedController,
      onClassTap: _openClassAssignment,
    );
  }
}

class _AssignmentFeedBody extends StatelessWidget {
  final ScrollController scrollController;
  final ClassFeedController classFeedController;
  final void Function(Map<String, dynamic> args) onClassTap;

  const _AssignmentFeedBody({
    super.key,
    required this.scrollController,
    required this.classFeedController,
    required this.onClassTap,
  });

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
                          controller: scrollController,
                          itemCount: classFeedController.classList.length +
                              (classFeedController.isLoadingMore.value ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= classFeedController.classList.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                    child: CircularProgressIndicator()),
                              );
                            }
                            final c = classFeedController.classList[index];
                            final roleName = classFeedController.roleName;
                            return ClassCard(
                              data: c,
                              roleName: roleName,
                              showStudentCount: false,
                              onTap: () {
                                onClassTap({
                                  'sectionId': c.sectionId,
                                  'className': c.effectiveClassName,
                                  'subjectName': c.subjectNameTh.isNotEmpty
                                      ? c.subjectNameTh
                                      : c.subjectNameEn,
                                  'role': roleName,
                                });
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