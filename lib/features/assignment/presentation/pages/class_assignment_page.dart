import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:ui';

import '../../../../config/app_routes.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/linklian-bg.dart';
import '../../../../core/constants/linklian-icon.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/constants/strings.dart';
import '../../../classes/presentation/controllers/create_post_controller.dart';
import '../../../classes/presentation/widgets/class_info_popup.dart';
import '../../../classes/presentation/pages/class_detail_page.dart' show BlurIconButton;
import '../../../auth/controller/auth_controller.dart';
import '../../../layout/controllers/navigation_controller.dart';
import '../../../layout/widgets/activeIcon.dart';
import '../controllers/class_assignment_controller.dart';
import '../widgets/assignment_card.dart';
import '../widgets/assignment_filter_dropdown.dart';

class ClassAssignmentPage extends StatefulWidget {
  const ClassAssignmentPage({super.key});

  @override
  State<ClassAssignmentPage> createState() => _ClassAssignmentPageState();
}

class _ClassAssignmentPageState extends State<ClassAssignmentPage> {
  late final NavigationController _navController;
  final ScrollController _scrollController = ScrollController();

  /// Nullable — controller may not yet be registered when layout.dart
  /// eagerly builds this page inside an AnimatedSlide / Stack.
  ClassAssignmentController? _controller;

  bool get isTeacher => _controller?.isTeacher ?? false;

  @override
  void initState() {
    super.initState();
    _navController = Get.find<NavigationController>();

    _tryFindController();
    ever<bool>(_navController.isShowingClassAssignment, (showing) {
      if (!mounted) return;
      if (showing && _controller == null) {
        _tryFindController();
        if (_controller != null) setState(() {});
      } else if (!showing) {
        _controller = null;
        setState(() {});
      }
    });

    ever<Map<String, dynamic>?>(_navController.classAssignmentArgs, (args) {
      if (args != null && mounted) {
        _tryFindController();
        _controller?.reinitialise(args);
        if (mounted) setState(() {});
      }
    });

    _scrollController.addListener(_onScroll);
  }

  void _tryFindController() {
    if (Get.isRegistered<ClassAssignmentController>()) {
      _controller = Get.find<ClassAssignmentController>();
    } else {
      _controller = null;
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _controller?.loadMoreAssignments();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  bool get _isStudent {
    final auth = Get.find<AuthController>();
    final role = auth.roleName.value;
    return role == 'high school student' || role == 'uni student';
  }

  List<BottomNavigationBarItem> get _navItems {
    if (_isStudent) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(LinkLianIcon.homework),
          activeIcon: ActiveNavIcon(icon: LinkLianIcon.homework),
          label: AppStrings.homework,
        ),
        BottomNavigationBarItem(
          icon: Icon(LinkLianIcon.classroom),
          activeIcon: ActiveNavIcon(icon: LinkLianIcon.classroom),
          label: AppStrings.classroom,
        ),
        BottomNavigationBarItem(
          icon: Icon(LinkLianIcon.community),
          activeIcon: ActiveNavIcon(icon: LinkLianIcon.community),
          label: AppStrings.community,
        ),
        BottomNavigationBarItem(
          icon: Icon(LinkLianIcon.profile),
          activeIcon: ActiveNavIcon(icon: LinkLianIcon.profile),
          label: AppStrings.profile,
        ),
      ];
    } else {
      return const [
        BottomNavigationBarItem(
          icon: Icon(LinkLianIcon.homework),
          activeIcon: ActiveNavIcon(icon: LinkLianIcon.homework),
          label: AppStrings.homework,
        ),
        BottomNavigationBarItem(
          icon: Icon(LinkLianIcon.classroom),
          activeIcon: ActiveNavIcon(icon: LinkLianIcon.classroom),
          label: AppStrings.classroom,
        ),
        BottomNavigationBarItem(
          icon: Icon(LinkLianIcon.profile),
          activeIcon: ActiveNavIcon(icon: LinkLianIcon.profile),
          label: AppStrings.profile,
        ),
      ];
    }
  }

  void _onNavTap(int index) {
    if (index == 0) {
      _navController.hideClassAssignment();
      return;
    }

    _navController.changeTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      extendBody: true,
      // Bottom Navigation Bar
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: 0,
          onTap: _onNavTap,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primaryPalette[900],
          unselectedItemColor: AppColors.primaryPalette[800],
          backgroundColor: AppColors.primaryPalette[200],
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: _navItems,
        ),
      ),
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
                    onBack: () => _navController.hideClassAssignment(),
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

              return SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppSizes.md,
                  0,
                  AppSizes.md,
                  MediaQuery.of(context).padding.bottom + 80,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == controller.filteredAssignments.length) {
                        return Obx(() {
                          if (controller.isLoadingMore.value) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return const SizedBox.shrink();
                        });
                      }

                      final assignment = controller.filteredAssignments[index];
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
                    },
                    childCount: controller.filteredAssignments.length + 1,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

//  Header

class _ClassAssignmentHeader extends StatefulWidget {
  final ClassAssignmentController controller;
  final bool isTeacher;
  final bool isCollapsed;
  final double shrinkRatio;
  final VoidCallback onBack;

  const _ClassAssignmentHeader({
    required this.controller,
    required this.isTeacher,
    required this.isCollapsed,
    required this.shrinkRatio,
    required this.onBack,
  });

  @override
  State<_ClassAssignmentHeader> createState() => _ClassAssignmentHeaderState();
}

class _ClassAssignmentHeaderState extends State<_ClassAssignmentHeader> {
  Color _textColor = Colors.white;
  List<Shadow> _textShadow = const [
    Shadow(blurRadius: 6, color: Colors.black54),
  ];

  @override
  void initState() {
    super.initState();
    _analyzeImageColor();
  }

  Future<void> _analyzeImageColor() async {
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(LinkLianBg.classCardHeader),
        maximumColorCount: 16,
      );

      final bgColor =
          palette.dominantColor?.color ??
          palette.vibrantColor?.color ??
          palette.mutedColor?.color ??
          const Color(0xFFCCBFA0);

      Color blended = _blendColor(bgColor, Colors.white, 0.15);
      blended = _blendColor(blended, const Color(0xFFFFF2DD), 0.5);
      blended = _blendColor(blended, const Color(0xFF93381B), 0.25);

      final effectiveLuminance = blended.computeLuminance();
      final useLightText = effectiveLuminance <= 0.5;

      if (mounted) {
        setState(() {
          _textColor = useLightText ? Colors.white : Colors.black87;
          _textShadow = useLightText
              ? [
                  Shadow(
                    blurRadius: 16,
                    color: const Color.fromARGB(255, 81, 81, 81).withOpacity(0.75),
                    offset: const Offset(0, 1),
                  ),
                ]
              : [
                  Shadow(
                    blurRadius: 8,
                    color: Colors.white.withOpacity(0.25),
                    offset: const Offset(0, 1),
                  ),
                ];
        });
      }
    } catch (_) {
      // safe default
    }
  }

  Color _blendColor(Color src, Color dst, double dstOpacity) {
    final r = (src.red * (1 - dstOpacity) + dst.red * dstOpacity).round().clamp(0, 255);
    final g = (src.green * (1 - dstOpacity) + dst.green * dstOpacity).round().clamp(0, 255);
    final b = (src.blue * (1 - dstOpacity) + dst.blue * dstOpacity).round().clamp(0, 255);
    return Color.fromARGB(255, r, g, b);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final expandRatio = (1.0 - widget.shrinkRatio).clamp(0.0, 1.0);

    final titleFontSize = 18.0 + (6.0 * expandRatio);
    final sectionFontSize = 14.0 + (2.0 * expandRatio);
    final teacherFontSize = 14.0 + (2.0 * expandRatio);
    final iconSize = 24.0 + (4.0 * expandRatio);
    final addIconSize = 24.0 + (4.0 * expandRatio);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        Image.network(LinkLianBg.classCardHeader, fit: BoxFit.cover),

        // Gradient layer
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.white,
                AppColors.primaryPalette[100]!.withOpacity(0.75),
                AppColors.primaryPalette[200]!.withOpacity(0.5),
                AppColors.primaryPalette[700]!.withOpacity(0.25),
              ],
            ),
          ),
        ),

        // Content
        SafeArea(
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
                      BlurIconButton(
                        icon: LinkLianIcon.back,
                        iconSize: 24,
                        onTap: widget.onBack,
                      ),
                      const Spacer(),
                      BlurIconButton(
                        icon: Icons.search,
                        iconSize: iconSize,
                        onTap: () {
                          debugPrint('🔍 Search button tapped - navigating to SearchAssignmentPage');
                          Get.toNamed(
                            '/search-assignment',
                            arguments: {
                              'sectionId': controller.sectionId,
                              'subjectName': controller.subjectName,
                              'role': controller.userRole.value,
                            },
                          );
                        },
                      ),
                      if (widget.isTeacher) ...[
                        const SizedBox(width: 12),
                        BlurIconButton(
                          icon: LinkLianIcon.add,
                          iconSize: addIconSize,
                          onTap: () async {
                            final result = await Get.toNamed(
                              AppRoutes.createPost,
                              arguments: {
                                'mode': CreatePostMode.create,
                                'source': CreatePostSource.classAssignment,
                                'sectionId': controller.sectionId,
                                'presetSectionIds': [controller.sectionId],
                                'lockSection': true,
                                'postType': 'assignment',
                                'lockPostType': true,
                              },
                            );

                            if (result?['success'] == true) {
                              controller.refreshAssignments();
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 8 + (8 * expandRatio)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          controller.subjectName,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w700,
                            color: _textColor,
                            shadows: _textShadow,
                          ),
                          maxLines: expandRatio > 0.5 ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      BlurIconButton(
                        icon: Icons.info_outline,
                        iconSize: 22,
                        onTap: () => _showClassInfoPopup(context),
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
                          color: _textColor.withOpacity(0.85),
                          shadows: _textShadow,
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
                                color: _textColor.withOpacity(0.75),
                                shadows: _textShadow,
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
                                  color: _textColor,
                                  shadows: _textShadow,
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
      ],
    );
  }

  void _showClassInfoPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClassInfoPopup(sectionId: widget.controller.sectionId),
    );
  }
}

//  Filter section

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
        final offset = scrollController.hasClients
            ? scrollController.offset
            : 0;
        final isCollapsed = offset > 90;
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