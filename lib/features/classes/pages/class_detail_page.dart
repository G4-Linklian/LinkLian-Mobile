import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:ui';
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
import '../../../core/utils/logger.dart';

class ClassDetailPage extends StatefulWidget {
  const ClassDetailPage({super.key});

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage> {
  late ClassDetailController controller;
  late bool isTeacher;
  String? controllerTag;

  @override
  void initState() {
    super.initState();
    _initController();

    ever(Get.find<NavigationController>().classDetailArgs, (args) {
      if (args == null || !mounted) return;
      controller.initializeWithArgs(args);
    });
  }

  void _initController() {
    final auth = Get.find<AuthController>();
    isTeacher =
        auth.roleName.value == 'teacher' || auth.roleName.value == 'instructor';

    final navController = Get.find<NavigationController>();
    final args = navController.classDetailArgs.value;

    if (args != null && args['sectionId'] != null) {
      controllerTag = 'class_detail_${args['sectionId']}';
    }

    if (!Get.isRegistered<ClassDetailController>(tag: controllerTag)) {
      Get.put(ClassDetailController(), tag: controllerTag, permanent: true);
    }
    controller = Get.find<ClassDetailController>(tag: controllerTag);

    if (args != null) {
      controller.initializeWithArgs(args);
    }

    controller.scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!controller.scrollController.hasClients) return;
    if (controller.scrollController.position.pixels >=
        controller.scrollController.position.maxScrollExtent - 200) {
      controller.fetchPosts(loadMore: true);
    }
  }

  @override
  void dispose() {
    controller.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      extendBodyBehindAppBar: false,
      body: RefreshIndicator(
        color: AppColors.primaryPalette[500],
        onRefresh: () async {
          appLog.info('[Class detail page] Pull to refresh', actionPage: 'ClassDetailScreen');
          await controller.fetchPosts();
        },
        child: CustomScrollView(
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
                  final double maxHeight = 210;
                  final double minHeight = 120;
                  final double currentHeight = constraints.maxHeight;
                  final double shrinkRatio =
                      ((maxHeight - currentHeight) / (maxHeight - minHeight))
                          .clamp(0.0, 1.0);
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
                scrollController: controller.scrollController,
                child: _FilterSection(
                  controller: controller,
                  isTeacher: isTeacher,
                  scrollController: controller.scrollController,
                ),
              ),
            ),
            // Posts List
            Obx(() {
              if (controller.isLoading.value) {
                return const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 400,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              if (controller.posts.isEmpty) {
                return SliverToBoxAdapter(
                  child: ListView(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
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
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final post = controller.posts[index];
                      return CardPost(
                        post: post,
                        classDetailController: controller,
                        onSelectForAI: isTeacher
                            ? null
                            : (postId) {
                                controller.togglePostSelection(postId);
                              },
                      );
                    },
                    childCount:
                        controller.posts.length +
                        (controller.isLoadingMore.value ? 1 : 0),
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

// ─────────────────────────────────────────────
// Header — StatefulWidget เพื่อ hold adaptive text color
// ─────────────────────────────────────────────

class _ClassDetailHeader extends StatefulWidget {
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
  State<_ClassDetailHeader> createState() => _ClassDetailHeaderState();
}

class _ClassDetailHeaderState extends State<_ClassDetailHeader> {
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

      // ดึง dominant color จากภาพพื้นหลัง
      final bgColor =
          palette.dominantColor?.color ??
          palette.vibrantColor?.color ??
          palette.mutedColor?.color ??
          const Color(0xFFCCBFA0); // fallback warm neutral

      // ── คำนวณ composite color หลัง gradient overlay ──────────────────
      // Layer 1: AppColors.white (opacity 1.0 ที่ top)
      // Layer 2: primaryPalette[100] = 0xFFFFF2DD, opacity 0.5
      // Layer 3: primaryPalette[800] = 0xFF93381B, opacity 0.25
      // บริเวณ text อยู่ใกล้ bottom → ได้รับผลหลักจาก layer 2 + 3

      // blend ทีละ layer บน bgColor
      Color blended = _blendColor(
        bgColor,
        Colors.white,
        0.15,
      ); // layer top (ลดลงเพราะ text อยู่ล่าง)
      blended = _blendColor(blended, const Color(0xFFFFF2DD), 0.5); // layer 2
      blended = _blendColor(blended, const Color(0xFF93381B), 0.25); // layer 3

      final effectiveLuminance = blended.computeLuminance();

      // WCAG: > 0.5 → background สว่าง → text ดำ
      //        ≤ 0.5 → background มืด → text ขาว
      final useLightText = effectiveLuminance <= 0.5;

      if (mounted) {
        setState(() {
          _textColor = useLightText ? Colors.white : Colors.black87;
          _textShadow = useLightText
              ? [
                  Shadow(
                    blurRadius: 16,
                    color: const Color.fromARGB(
                      255,
                      81,
                      81,
                      81,
                    ).withOpacity(0.75),
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
      // safe default: white text + dark shadow
    }
  }

  /// Alpha compositing: dst ทับบน src ด้วย opacity ของ dst
  Color _blendColor(Color src, Color dst, double dstOpacity) {
    final r = (src.red * (1 - dstOpacity) + dst.red * dstOpacity).round().clamp(
      0,
      255,
    );
    final g = (src.green * (1 - dstOpacity) + dst.green * dstOpacity)
        .round()
        .clamp(0, 255);
    final b = (src.blue * (1 - dstOpacity) + dst.blue * dstOpacity)
        .round()
        .clamp(0, 255);
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
        // รูปภาพ — ไม่เปลี่ยน
        Image.network(LinkLianBg.classCardHeader, fit: BoxFit.cover,),

        // Gradient layer — ไม่เปลี่ยน
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
                        onTap: () =>
                            Get.find<NavigationController>().hideClassDetail(),
                      ),
                      const Spacer(),
                      BlurIconButton(
                        icon: Icons.search,
                        iconSize: iconSize,
                        onTap: () => Get.toNamed(
                          AppRoutes.searchPost,
                          arguments: {
                            'sectionId': controller.sectionId.value,
                            'subjectName': controller.subjectNameTh.value,
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      BlurIconButton(
                        icon: LinkLianIcon.add,
                        iconSize: addIconSize,
                        onTap: () async {
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
                      ),
                    ],
                  ),
                  SizedBox(height: 8 + (8 * expandRatio)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Obx(
                          () => Text(
                            controller.subjectNameTh.value,
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
                      ),
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
                      child: Obx(
                        () => Text(
                          controller.effectiveClassName.value,
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
                                color: _textColor.withOpacity(
                                  0.75,
                                ), 
                                shadows: _textShadow,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                controller.teacherName.value,
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
      builder: (context) =>
          ClassInfoPopup(sectionId: widget.controller.sectionId.value!),
    );
  }
}

// ─────────────────────────────────────────────
// BlurIconButton — วงกลม blur ของแต่ละปุ่ม
// public เพื่อ reuse ใน ClassAssignmentPage
// และ CommunityDetailPage
// ─────────────────────────────────────────────

class BlurIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double iconSize;
  final double buttonSize;
  final Color iconColor;

  const BlurIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconSize = 32,
    this.buttonSize = 40,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: AppColors.primaryPalette[800]!.withOpacity(0.25),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.20),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 8,
                  spreadRadius: 16,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: iconSize, color: iconColor),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Filter section — ไม่เปลี่ยน
// ─────────────────────────────────────────────

class _FilterSection extends StatelessWidget {
  final ClassDetailController controller;
  final bool isTeacher;
  final ScrollController scrollController;

  const _FilterSection({
    required this.controller,
    required this.isTeacher,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        if (!scrollController.hasClients ||
            scrollController.positions.length != 1) {
          return _buildContent(0, false);
        }
        final offset = scrollController.offset;
        final isCollapsed = offset > 90;
        return _buildContent(isCollapsed ? 8.0 : 12.0, isCollapsed);
      },
    );
  }

  Widget _buildContent(double topPadding, bool isCollapsed) {
    return Container(
      height: 64,
      padding: EdgeInsets.fromLTRB(AppSizes.md, topPadding, AppSizes.md, 8),
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
              if (count == 0) return const SizedBox.shrink();
              
              return TextButton.icon(
                onPressed: controller.generateAISummary,
                icon: Icon(
                  Icons.auto_awesome,
                  color: AppColors.primaryPalette[500],
                  size: 18,
                ),
                label: Text(
                  'เริ่มสรุปเนื้อหา',
                  style: TextStyle(
                    color: AppColors.primaryPalette[500],
                    fontWeight: FontWeight.w600,
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
      itemBuilder: (context) => ClassPostFilter.values
          .map(
            (filter) => PopupMenuItem<ClassPostFilter>(
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
            ),
          )
          .toList(),
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
  final ScrollController scrollController;

  _FilterSectionDelegate({required this.child, required this.scrollController});

  @override
  double get minExtent => 64;

  @override
  double get maxExtent => 64;

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