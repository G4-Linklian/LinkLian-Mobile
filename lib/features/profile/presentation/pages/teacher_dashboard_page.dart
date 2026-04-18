import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/constants/linklian-icon.dart';
import '../../../../config/app_routes.dart';
import '../../../auth/controller/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/assignment_detail_card.dart';
import '../../data/models/dashboard_model.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  late DashboardController controller;
  late AuthController authController;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    authController = Get.find<AuthController>();
    controller = Get.find<DashboardController>();

    final userId = authController.userId.value;
    if (userId == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ข้อผิดพลาด'),
          content: const Text('ไม่สามารถหา ID ผู้ใช้'),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('ปิด')),
          ],
        ),
      );
      return;
    }

    // Set role type first before loading available months
    controller.setRoleType('TEACHER');
    // Load available months - this will auto-load dashboard with default month
    controller.loadAvailableMonths(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LinkLianIcon.back, color: AppColors.primaryPalette[700]),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'แดชบอร์ด',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.dashboard.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Obx(
                  () =>
                      Text('เกิดข้อผิดพลาด: ${controller.errorMessage.value}'),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => ElevatedButton(
                    onPressed: () {
                      final userId = authController.userId.value;
                      if (userId != null) {
                        controller.loadDashboard(
                          userId: userId,
                          reportMonth: controller.selectedMonth.value,
                          roleType: 'TEACHER',
                        );
                      }
                    },
                    child: const Text('ลองอีกครั้ง'),
                  ),
                ),
              ],
            ),
          );
        }

        final dashboard = controller.dashboard.value;
        if (dashboard == null) {
          return const Center(child: Text('ไม่มีข้อมูล'));
        }

        return SingleChildScrollView(
          clipBehavior: Clip.none,
          child: Column(
            children: [
              // Month Selector
              Material(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: _MonthSelector(controller: controller),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Stats - use overview from response
                    _OverviewStats(assets: _mapOverviewToAssets(dashboard.overview)),
                    const SizedBox(height: 24),

                    // Popular Posts - use popularPosts from overview
                    if (dashboard.overview.popularPosts.isNotEmpty) ...[
                      Text(
                        'โพสต์ยอดนิยม',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ..._buildPopularPostsCards(
                        dashboard.overview.popularPosts,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Sections
                    Text(
                      'ภาพรวมรายห้องเรียน',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ..._buildSectionCards(dashboard.sections),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  List<Widget> _buildPopularPostsCards(List<PopularPost> items) {
    if (items.isEmpty) {
      return [];
    }

    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final post = entry.value;

      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with number badge and title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryPalette[200],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '#${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryPalette[600],
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title ?? 'ไม่มีหัวข้อ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${post.bookmarkCount} บุ๊กมาร์ก',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Section tags
              if (post.sections?.isNotEmpty ?? false)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: (post.sections ?? []).map((section) {
                    final subjectName =
                        section['subject_name'] ??
                        section['subject'] ??
                        'ไม่ระบุ';
                    final sectionName = section['section_name'] ?? 'ไม่ระบุ';
                    final sectionId = section['section_id'] ?? 0;
                    final sectionPostId = section['post_id'];

                    return Material(
                      color: AppColors.primaryPalette[100],
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () {
                          final usePostId = sectionPostId ?? post.postId;
                          final parsedPostId =
                              int.tryParse(usePostId?.toString() ?? '0') ?? 0;

                          if (parsedPostId == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('โพสต์ ID ไม่ถูกต้อง'),
                              ),
                            );
                            return;
                          }

                          Get.toNamed(
                            AppRoutes.comment,
                            arguments: {
                              'postId': parsedPostId,
                              'sectionId': sectionId,
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            '$subjectName • $sectionName',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primaryPalette[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildSectionCards(List sections) {
    return sections.map((section) {
      return SectionDetailCard(section: section);
    }).toList();
  }

  /// Convert DashboardOverview to Map for _OverviewStats
  Map<String, dynamic> _mapOverviewToAssets(DashboardOverview overview) {
    return {
      'totalFiles': overview.totalFiles,
      'totalLives': overview.totalLives,
      'totalAssignments': overview.totalAssignments,
      'filesChange': overview.filesChange,
      'livesChange': overview.livesChange,
      'assignmentsChange': overview.assignmentsChange,
    };
  }
}

class _MonthSelector extends StatelessWidget {
  final DashboardController controller;

  const _MonthSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          final RenderBox button = context.findRenderObject() as RenderBox;
          final RenderBox overlay =
              Overlay.of(context).context.findRenderObject() as RenderBox;
          final buttonWidth = button.size.width;
          final buttonPos = button.localToGlobal(
            Offset.zero,
            ancestor: overlay,
          );

          final monthList = controller.availableMonths.toSet().toList();

          showMenu<String>(
            context: context,
            position: RelativeRect.fromLTRB(
              buttonPos.dx,
              buttonPos.dy + button.size.height + 8,
              overlay.size.width - (buttonPos.dx + buttonWidth),
              0,
            ),
            constraints: BoxConstraints(minWidth: buttonWidth),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            items: monthList
                .map(
                  (month) => PopupMenuItem<String>(
                    value: month,
                    child: SizedBox(
                      width: buttonWidth - 32,
                      child: Text(
                        controller.formatMonth(month),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ).then((month) {
            if (month != null) {
              controller.selectMonth(month);
              // selectMonth จะ auto-load dashboard ทำแทน
            }
          });
        },
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primaryPalette[300]!, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Obx(
                  () => Text(
                    controller.selectedMonth.value.isEmpty
                        ? (controller.availableMonths.isEmpty
                              ? 'เลือกเดือน'
                              : controller.formatMonth(
                                  controller.availableMonths.first,
                                ))
                        : controller.formatMonth(
                            controller.selectedMonth.value,
                          ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              Icon(
                Icons.expand_more_rounded,
                color: AppColors.primaryPalette[700],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewStats extends StatelessWidget {
  final Map<String, dynamic> assets;

  const _OverviewStats({required this.assets});

  int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _CompactStatCard(
            icon: LinkLianIcon.fileDescription,
            label: 'ไฟล์เอกสาร',
            value: (assets['totalFiles'] ?? 0).toString(),
            change: _safeToInt(assets['filesChange']),
            color: AppColors.primaryPalette[700]!,
          ),
          const SizedBox(width: 12),
          _CompactStatCard(
            icon: LinkLianIcon.broadcast,
            label: 'จำนวนไลฟ์',
            value: (assets['totalLives'] ?? 0).toString(),
            change: _safeToInt(assets['livesChange']),
            color: AppColors.primaryPalette[700]!,
          ),
          const SizedBox(width: 12),
          _CompactStatCard(
            icon: LinkLianIcon.alignCenter,
            label: 'งานทั้งหมด',
            value: (assets['totalAssignments'] ?? 0).toString(),
            change: _safeToInt(assets['assignmentsChange']),
            color: AppColors.primaryPalette[700]!,
          ),
        ],
      ),
    );
  }
}

class _CompactStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int change;
  final Color color;

  const _CompactStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.change,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            change >= 0 ? '+$change' : '$change',
            style: TextStyle(
              fontSize: 10,
              color: change >= 0 ? Colors.orange : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
