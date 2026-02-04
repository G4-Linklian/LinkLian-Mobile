import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/constants/linklian-icon.dart';
import '../../../core/constants/linklian-bg.dart';
import '../../../core/utils/dialog_helper.dart';
import '../controllers/class_detail_controller.dart';
import '../controllers/class_detail_filter.dart';
import '../../../config/app_routes.dart';
import '../widgets/card_post.dart';
import '../controllers/create_post_controller.dart';
import '../../auth/controller/auth_controller.dart';
import '../widgets/class_info_popup.dart';
import '../../layout/controllers/navigation_controller.dart';

class ClassDetailPage extends StatefulWidget {
  const ClassDetailPage({super.key});

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage> {
  late ClassDetailController controller;
  late bool isTeacher;
  final ValueNotifier<double> _scrollOffset = ValueNotifier(0);
  String? controllerTag; // ✅ เพิ่ม tag เพื่อแยก instance ต่าง class
  
  @override
  void initState() {
    super.initState();
    _initController();
  }
  
  void _initController() {
    final auth = Get.find<AuthController>();
    isTeacher = auth.roleName.value == 'teacher' || auth.roleName.value == 'instructor';
    
    // Get args from NavigationController
    final navController = Get.find<NavigationController>();
    final args = navController.classDetailArgs.value;
    
    // ✅ สร้าง unique tag สำหรับแต่ละ class
    if (args != null && args['sectionId'] != null) {
      controllerTag = 'class_detail_${args['sectionId']}';
    }
    
    // ✅ Initialize or get existing controller with tag
    if (!Get.isRegistered<ClassDetailController>(tag: controllerTag)) {
      Get.put(ClassDetailController(), tag: controllerTag);
    }
    controller = Get.find<ClassDetailController>(tag: controllerTag);
    
    // Initialize with args if available
    if (args != null) {
      controller.initializeWithArgs(args);
    }
    
    // Setup scroll listener
    controller.scrollController.addListener(_onScroll);
  }
  
  void _onScroll() {
    _scrollOffset.value = controller.scrollController.offset;
    if (controller.scrollController.position.pixels >=
        controller.scrollController.position.maxScrollExtent - 200) {
      controller.fetchPosts(loadMore: true);
    }
  }
  
  @override
  void dispose() {
    controller.scrollController.removeListener(_onScroll);
    
    // ✅ ลบ controller เมื่อออกจากหน้า (ประหยัด memory และ reset filter)
    if (controllerTag != null) {
      Get.delete<ClassDetailController>(tag: controllerTag);
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      extendBodyBehindAppBar: false,
      body: CustomScrollView(
        controller: controller.scrollController,
        slivers: [
          // Collapsible Header
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
                // Calculate how much we've scrolled (0 = expanded, 1 = collapsed)
                final double maxHeight = 210;
                final double minHeight = 120;
                final double currentHeight = constraints.maxHeight;
                final double shrinkRatio = ((maxHeight - currentHeight) / (maxHeight - minHeight)).clamp(0.0, 1.0);
                final bool isCollapsed = shrinkRatio > 0.7;
                
                return _ClassDetailHeader(
                  controller: controller,
                  isTeacher: isTeacher,
                  isCollapsed: isCollapsed,
                  shrinkRatio: shrinkRatio,
                );
              },
            ),
          ),
          // Filter Section
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterSectionDelegate(
              child: _FilterSection(
                controller: controller,
                isTeacher: isTeacher,
              ),
            ),
          ),
          // Posts List
          Obx(() {
            if (controller.isLoading.value) {
              return SliverToBoxAdapter(
                child: const SizedBox(
                  height: 400,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (controller.posts.isEmpty) {
              return SliverToBoxAdapter(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await controller.fetchPosts();
                    DialogHelper.showNotification(
                      title: 'โพสต์ถูกโหลดแล้ว',
                      message: 'ข้อมูลโพสต์ได้รับการอัปเดตแล้ว',
                      type: NotificationType.success,
                      titleSize: 18.0,
                    );
                  },
                  child: ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 200),
                      Center(
                        child: Text(
                          'ยังไม่มีโพสต์ในห้องนี้',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= controller.posts.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final post = controller.posts[index];
                    return CardPost(
                      post: post,
                      classDetailController: controller, // ✅ ส่ง controller เข้าไป
                      onSelectForAI: isTeacher
                          ? null
                          : (postId) {
                              controller.togglePostSelection(postId);
                            },
                    );
                  },
                  childCount: controller.posts.length +
                      (controller.isLoadingMore.value ? 1 : 0),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ClassDetailHeader extends StatelessWidget {
  final ClassDetailController controller;
  final bool isTeacher;
  final bool isCollapsed;
  final double shrinkRatio;

  const _ClassDetailHeader({
    required this.controller,
    required this.isTeacher,
    required this.isCollapsed,
    required this.shrinkRatio,
  });

  @override
  Widget build(BuildContext context) {
    final expandRatio = (1.0 - shrinkRatio).clamp(0.0, 1.0);
    
    // Dynamic sizes based on shrink ratio
    final titleFontSize = 18.0 + (6.0 * expandRatio); // 18-24
    final sectionFontSize = 14.0 + (2.0 * expandRatio); // 14-16
    final teacherFontSize = 12.0 + (2.0 * expandRatio); // 12-14
    final iconSize = 22.0 + (4.0 * expandRatio); // 22-26
    final addIconSize = 24.0 + (4.0 * expandRatio); // 24-28
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24 * expandRatio),
          bottomRight: Radius.circular(24 * expandRatio),
        ),
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
                // Top Action Bar - Always visible
                Row(
                  children: [
                    IconButton(
                      icon: Icon(LinkLianIcon.back, color: AppColors.primaryPalette[700]!),
                      onPressed: () {
                        final navController = Get.find<NavigationController>();
                        navController.hideClassDetail();
                      },
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
                            'sectionId': controller.sectionId.value,
                            'subjectName': controller.subjectNameTh.value,
                          },
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        LinkLianIcon.add,
                        color: AppColors.primaryPalette[500],
                        size: addIconSize,
                      ),
                      onPressed: () async {
                        final result = await Get.toNamed(
                          AppRoutes.createPost,
                          arguments: {
                            'mode': CreatePostMode.create,
                            'source': CreatePostSource.classDetail,
                            'sectionId': controller.sectionId.value,
                            'presetSectionIds': [controller.sectionId.value],
                            'lockSection': true,
                          },
                        );

                        if (result?['success'] == true) {
                          controller.fetchPosts();
                          controller.scrollToTop();
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 4 + (4 * expandRatio)),
                // Class Name and Info Button - Always visible
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Obx(() => Text(
                        controller.subjectNameTh.value,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                        maxLines: expandRatio > 0.5 ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                      )),
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
                // Expandable content with opacity transition
                if (expandRatio > 0.3) ...[
                  SizedBox(height: 4 * expandRatio),
                  Opacity(
                    opacity: ((expandRatio - 0.3) / 0.7).clamp(0.0, 1.0),
                    child: Obx(() => Text(
                      controller.effectiveClassName.value,
                      style: TextStyle(
                        fontSize: sectionFontSize,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )),
                  ),
                  SizedBox(height: 4 * expandRatio),
                  Opacity(
                    opacity: ((expandRatio - 0.3) / 0.7).clamp(0.0, 1.0),
                    child: Obx(() => Row(
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
                            controller.teacherName.value,
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
                    )),
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
      builder: (context) => ClassInfoPopup(
        sectionId: controller.sectionId.value!,
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final ClassDetailController controller;
  final bool isTeacher;

  const _FilterSection({required this.controller, required this.isTeacher});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Row(
        children: [
          Obx(
            () => _FilterDropdown(
              selected: controller.selectedFilter.value,
              onChanged: (filter) => controller.changeFilter(filter),
            ),
          ),
          const Spacer(),
          if (!isTeacher)
            Obx(() {
              final count = controller.selectedPostIdsForAI.length;
              return TextButton.icon(
                onPressed: count > 0 ? controller.generateAISummary : null,
                icon: Icon(
                  Icons.auto_awesome,
                  color: count > 0
                      ? AppColors.primaryPalette[500]
                      : Colors.grey,
                  size: 18,
                ),
                label: Text(
                  count > 0
                      ? 'AI สรุปเนื้อหา ($count)'
                      : 'AI สรุปเนื้อหา',
                  style: TextStyle(
                    color: count > 0
                        ? AppColors.primaryPalette[500]
                        : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final ClassPostFilter selected;
  final ValueChanged<ClassPostFilter> onChanged;

  const _FilterDropdown({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ClassPostFilter>(
      onSelected: (value) => onChanged(value),
      itemBuilder: (context) => ClassPostFilter.values.map((filter) {
        return PopupMenuItem<ClassPostFilter>(
          value: filter,
          child: Center(
            child: Text(
              filter.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryPalette[900],
                height: 1.0,
              ),
            ),
          ),
        );
      }).toList(),
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.primaryPalette[300],
      child: Container(
        width: 115,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryPalette[300],
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              selected.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryPalette[900],
                height: 1.0,
              ),
            ),
            Icon(
              LinkLianIcon.filterpost,
              size: 18,
              color: AppColors.primaryPalette[700],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSectionDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _FilterSectionDelegate({required this.child});

  @override
  double get minExtent => 64;

  @override
  double get maxExtent => 64;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.white,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_FilterSectionDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
