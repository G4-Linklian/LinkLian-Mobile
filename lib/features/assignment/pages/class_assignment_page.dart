import 'package:LinkLian/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../config/app_routes.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/linklian-bg.dart';
import '../../../core/constants/linklian-icon.dart';
import '../../../core/constants/sizes.dart';
import '../../classes/controllers/create_post_controller.dart';
import '../../classes/widgets/class_info_popup.dart';
import '../controllers/class_assignment_controller.dart';
import '../widgets/assignment_card.dart';
import '../widgets/assignment_filter_dropdown.dart';

class ClassAssignmentPage extends StatefulWidget {
  const ClassAssignmentPage({super.key});

  @override
  State<ClassAssignmentPage> createState() => _ClassAssignmentPageState();
}

class _ClassAssignmentPageState extends State<ClassAssignmentPage> {
  late final ClassAssignmentController controller;
  final ScrollController _scrollController = ScrollController();

  bool get isTeacher => controller.isTeacher;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ClassAssignmentController>();
        _scrollController.addListener(_onScroll);

  }
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      controller.loadMoreAssignments();
    }
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
      extendBodyBehindAppBar: false,
      body: RefreshIndicator(
        color: AppColors.primaryPalette[500],
        onRefresh: controller.refreshAssignments,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
            expandedHeight: 210,
            collapsedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double maxHeight = 210;
                final double minHeight = 120;
                final double currentHeight = constraints.maxHeight;
                final double shrinkRatio =
                    ((maxHeight - currentHeight) / (maxHeight - minHeight))
                        .clamp(0.0, 1.0);
                final bool isCollapsed = shrinkRatio > 0.7;

                return _ClassAssignmentHeader(
                  controller: controller,
                  isTeacher: isTeacher,
                  isCollapsed: isCollapsed,
                  shrinkRatio: shrinkRatio,
                );
              },
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterSectionDelegate(
              scrollController: _scrollController,
              child: _FilterSection(
                controller: controller,
                scrollController: _scrollController,
              ),
            ),
          ),

          // ← ย้าย Obx มาที่นี่แทน
          Obx(() {
            if (controller.isLoading.value) {
              return const SliverToBoxAdapter(
                child: SizedBox(
                  height: 400,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (controller.errorMessage.isNotEmpty) {
              return SliverToBoxAdapter(
                child: SizedBox(
                  height: 320,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LinkLianIcon.alertCircle,
                          size: 48,
                          color: AppColors.gray,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          controller.errorMessage.value,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.gray,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: controller.refreshAssignments,
                          child: Text(
                            'ลองใหม่',
                            style: TextStyle(
                              color: AppColors.primaryPalette[500],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (controller.filteredAssignments.isEmpty) {
              return SliverToBoxAdapter(
                child: RefreshIndicator(
                  color: AppColors.primaryPalette[500],
                  onRefresh: controller.refreshAssignments,
                  child: ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 200),
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              LinkLianIcon.assignment,
                              size: 64,
                              color: AppColors.gray,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'ไม่มีการบ้าน',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.gray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Render assignment cards
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index == controller.filteredAssignments.length) {
                        return Obx(() {
                          if (controller.isLoadingMore.value) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        });
                      }
                  final assignment = controller.filteredAssignments[index];
                  AppLogger.info(
                    '🎴 Rendering card $index: ${assignment.title} (ID: ${assignment.assignmentId})',
                  );

                  return AssignmentCard(
                    key: ValueKey('assignment_${assignment.assignmentId}'),
                    assignment: assignment,
                    isTeacher: controller.isTeacher,
                    onTap: () {
                      Get.toNamed(
                        AppRoutes.assignmentSubmission,
                        arguments: {'postId': assignment.postId},
                      );
                    },
                  );
                }, childCount: controller.filteredAssignments.length),
              ),
            );
          }),
        ],
      ),
    )
    );
  }
}

class _ClassAssignmentHeader extends StatelessWidget {
  final ClassAssignmentController controller;
  final bool isTeacher;
  final bool isCollapsed;
  final double shrinkRatio;

  const _ClassAssignmentHeader({
    required this.controller,
    required this.isTeacher,
    required this.isCollapsed,
    required this.shrinkRatio,
  });

  @override
  Widget build(BuildContext context) {
    final expandRatio = (1.0 - shrinkRatio).clamp(0.0, 1.0);

    final titleFontSize = 18.0 + (6.0 * expandRatio);
    final sectionFontSize = 14.0 + (2.0 * expandRatio);
    final teacherFontSize = 12.0 + (2.0 * expandRatio);
    final iconSize = 22.0 + (4.0 * expandRatio);
    final addIconSize = 24.0 + (4.0 * expandRatio);

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(LinkLianBg.classCardDefault),
          fit: BoxFit.cover,
          opacity: 0.9,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + (8 * expandRatio)),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        LinkLianIcon.back,
                        color: AppColors.primaryPalette[700]!,
                      ),
                      onPressed: () => Get.back(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 24,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.search,
                        color: AppColors.primaryPalette[700]!,
                        size: iconSize,
                      ),
                      onPressed: () {
                        Get.toNamed(
                          AppRoutes.searchPost,
                          arguments: {
                            'sectionId': controller.sectionId,
                            'subjectName': controller.subjectName,
                          },
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    if (isTeacher)
                      IconButton(
                        icon: Icon(
                          LinkLianIcon.add,
                          color: AppColors.primaryPalette[500],
                          size: addIconSize,
                        ),
                        onPressed: () {
                          Get.toNamed(
                            AppRoutes.createPost,
                            arguments: {
                              'mode': CreatePostMode.create,
                              'source': CreatePostSource.classDetail,
                              'sectionId': controller.sectionId,
                              'presetSectionIds': [controller.sectionId],
                              'lockSection': true,
                              'postType': 'assignment',
                              'lockPostType': true,
                            },
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    if (isTeacher) const SizedBox(width: 8),
                  ],
                ),
                SizedBox(height: 4 + (4 * expandRatio)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        controller.subjectName,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                        maxLines: expandRatio > 0.5 ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.info_outline,
                        color: AppColors.primaryPalette[600],
                        size: 24,
                      ),
                      onPressed: () => _showClassInfoPopup(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                if (expandRatio > 0.3) ...[
                  SizedBox(height: 4 * expandRatio),
                  Opacity(
                    opacity: ((expandRatio - 0.3) / 0.7).clamp(0.0, 1.0),
                    child: Text(
                      controller.className,
                      style: TextStyle(
                        fontSize: sectionFontSize,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 4 * expandRatio),
                  Opacity(
                    opacity: ((expandRatio - 0.3) / 0.7).clamp(0.0, 1.0),
                    child: Obx(
                      () => Row(
                        children: [
                          Text(
                            'ครูผู้สอน ',
                            style: TextStyle(
                              fontSize: teacherFontSize,
                              color: AppColors.black.withOpacity(0.6),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              controller.teacherName.value.isNotEmpty
                                  ? controller.teacherName.value
                                  : 'ไม่พบผู้สอนหลัก',
                              style: TextStyle(
                                fontSize: teacherFontSize,
                                fontWeight: FontWeight.w500,
                                color: AppColors.black.withOpacity(0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showClassInfoPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClassInfoPopup(sectionId: controller.sectionId),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final ClassAssignmentController controller;
  final ScrollController scrollController;

  const _FilterSection({
    required this.controller,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        // Calculate if header is collapsed
        final offset = scrollController.hasClients
            ? scrollController.offset
            : 0;
        final isCollapsed =
            offset > 90; // เมื่อ scroll เกิน 90px = header เริ่มยุบ

        // Dynamic padding: ตอนขยาย 12px ตอนยุบ 8px
        final topPadding = isCollapsed ? 8.0 : 12.0;

        return Container(
          height: 56,
          padding: EdgeInsets.fromLTRB(AppSizes.md, topPadding, AppSizes.md, 8),
          child: Row(
            children: [
              Obx(
                () => AssignmentFilterDropdown(
                  options: controller.filterOptions,
                  currentFilter: controller.currentFilter.value,
                  onFilterChanged: controller.applyFilter,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterSectionDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final ScrollController scrollController;

  _FilterSectionDelegate({required this.child, required this.scrollController});

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppColors.white, child: child);
  }

  @override
  bool shouldRebuild(_FilterSectionDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
