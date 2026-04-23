import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/constants/linklian-icon.dart';
import '../../../auth/controller/auth_controller.dart';
import '../../data/models/dashboard_model.dart';
import '../controllers/dashboard_controller.dart';
import 'teacher_dashboard_page.dart';
import '../../../layout/controllers/navigation_controller.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late DashboardController controller;
  late AuthController authController;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    // Get auth controller to access user ID
    authController = Get.find<AuthController>();
    
    // Get dashboard controller from GetX (registered in DashboardBinding)
    controller = Get.find<DashboardController>();

    // Get user ID from auth controller
    final userId = authController.userId.value;
    if (userId == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ข้อผิดพลาด'),
          content: const Text('ไม่สามารถหา ID ผู้ใช้'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('ปิด'),
            ),
          ],
        ),
      );
      return;
    }

    // Check if user is teacher or student and set role type
    final isTeacher = authController.roleName.value == 'teacher' || 
                      authController.roleName.value == 'instructor';
    controller.setRoleType(isTeacher ? 'TEACHER' : 'STUDENT');
    
    // Load available months - this will auto-load dashboard with default month
    controller.loadAvailableMonths(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Check user role - safely inside Obx
      final isTeacher = authController.roleName.value == 'teacher' || 
                        authController.roleName.value == 'instructor';

      // Show appropriate dashboard based on role
      return isTeacher 
          ? _buildTeacherDashboard(context)
          : _buildStudentDashboard(context);
    });
  }

  Widget _buildTeacherDashboard(BuildContext context) {
    return const TeacherDashboardPage();
  }

  Widget _buildStudentDashboard(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LinkLianIcon.back, color: AppColors.black),
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
                Obx(() => Text('เกิดข้อผิดพลาด: ${controller.errorMessage.value}')),
                const SizedBox(height: 16),
                Obx(
                  () => ElevatedButton(
                    onPressed: () {
                      final userId = authController.userId.value;
                      if (userId != null) {
                        controller.loadDashboard(
                          userId: userId,
                          reportMonth: controller.selectedMonth.value,
                          roleType: 'STUDENT',
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
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
                  child: _MonthSelector(controller: controller),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Stats
                    _OverviewStats(overview: dashboard.overview),
                    const SizedBox(height: 24),

                    // Summary Chart - before section cards
                    _buildSummaryChart(dashboard.overview),
                    const SizedBox(height: 24),

                    // Popular Posts
                    if (dashboard.overview.popularPosts.isNotEmpty) ...[
                      Text(
                        'โพสต์ยอดนิยม',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      ..._buildPopularPostsCards(dashboard.overview.popularPosts),
                      const SizedBox(height: 24),
                    ],

                    // Sections
                    Text(
                      'ภาพรวมรายวิชา',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
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

  List<Widget> _buildSectionCards(List<SectionDetail> items) {
    if (items.isEmpty) {
      return [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('ไม่มีข้อมูลรายวิชา'),
          ),
        ),
      ];
    }

    return items.map((section) {
      return _StudentSectionCard(section: section, context: context);
    }).toList();
  }

  Widget _buildSummaryChart(DashboardOverview overview) {
    final onTimeCount = overview.onTimeTotal;
    final lateCount = overview.lateTotal;
    final missingCount = overview.missingTotal;
    
    final maxValue = [onTimeCount, lateCount, missingCount]
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    
    const chartHeight = 140.0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'สรุปการส่งงาน',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // Bar chart
            SizedBox(
              height: chartHeight + 55,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBarChartItem(
                    label: 'ส่งแล้ว',
                    value: onTimeCount,
                    maxValue: maxValue,
                    chartHeight: chartHeight,
                    color: Colors.green,
                  ),
                  _buildBarChartItem(
                    label: 'ส่งล่าช้า',
                    value: lateCount,
                    maxValue: maxValue,
                    chartHeight: chartHeight,
                    color: Colors.orange,
                  ),
                  _buildBarChartItem(
                    label: 'ไม่ส่ง',
                    value: missingCount,
                    maxValue: maxValue,
                    chartHeight: chartHeight,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartItem({
    required String label,
    required int value,
    required double maxValue,
    required double chartHeight,
    required Color color,
  }) {
    final heightPercentage = maxValue > 0 ? value / maxValue : 0.0;
    final barHeight = chartHeight * heightPercentage;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Value text on top
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        // Bar
        Container(
          width: 40,
          height: barHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Label
        SizedBox(
          width: 50,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with number badge and title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
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
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${post.bookmarkCount} บุ๊กมาร์ก',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
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
          final RenderBox button =
              context.findRenderObject() as RenderBox;
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
            border: Border.all(
              color: AppColors.primaryPalette[300]!,
              width: 1,
            ),
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
                            : controller.formatMonth(controller.availableMonths.first))
                        : controller.formatMonth(controller.selectedMonth.value),
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
  final DashboardOverview overview;

  const _OverviewStats({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Cards Row - 3 main metrics
        Row(
          children: [
            Expanded(
              child: _CompactStatCard(
                icon: LinkLianIcon.alignCenter,
                label: 'งานทั้งหมด',
                value: overview.totalAssignments.toString(),
                color: AppColors.primaryPalette[700]!,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CompactStatCard(
                icon: LinkLianIcon.fileDescription,
                label: 'ส่งงานตรงเวลา',
                value: '${overview.onTimeRate.toStringAsFixed(0)}%',
                color: AppColors.primaryPalette[700]!,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CompactStatCard(
                icon: Icons.bookmark,
                label: 'บุ๊กมาร์ก',
                value: overview.bookmarksAdded.toString(),
                color: AppColors.primaryPalette[700]!,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompactStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _CompactStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentSectionCard extends StatefulWidget {
  final SectionDetail section;
  final BuildContext context;

  const _StudentSectionCard({
    required this.section,
    required this.context,
  });

  @override
  State<_StudentSectionCard> createState() => _StudentSectionCardState();
}

class _StudentSectionCardState extends State<_StudentSectionCard> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openSectionSheet(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject Name as main title
              Text(
                widget.section.subjectName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Assignment count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.section.assignments.isEmpty
                      ? Colors.grey[200]
                      : AppColors.primaryPalette[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LinkLianIcon.fileDescription,
                      size: 16,
                      color: widget.section.assignments.isEmpty
                          ? Colors.grey[600]
                          : AppColors.primaryPalette[700],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.section.assignments.isEmpty
                          ? 'ไม่มีงาน'
                          : '${widget.section.assignments.length} งาน',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: widget.section.assignments.isEmpty
                            ? Colors.grey[600]
                            : AppColors.primaryPalette[700],
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.section.assignments.isNotEmpty) ...[
                const SizedBox(height: 16),
                // Submission Status Chart
                _buildSubmissionStatusChart(widget.section),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSectionSheet() async {
    if (_isNavigating) return;
    
    final authController = Get.find<AuthController>();
    
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => _SectionDetailSheet(
        section: widget.section,
        initialTab: 0,
      ),
    );

    // ตรวจสอบ result
    if (!mounted) return;
    if (result == null) return;
    if (_isNavigating) return;
    
    _isNavigating = true;

    try {
      if (result['action'] == 'assignment') {
        final navController = Get.find<NavigationController>();
        navController.showClassAssignment({
          'sectionId': widget.section.sectionId,
          'className': widget.section.sectionName,
          'subjectName': widget.section.subjectName,
          'role': authController.roleName.value,
        });
        if (mounted) {
          Navigator.of(context).maybePop();
        }
      } else if (result['action'] == 'class_detail') {
        final navController = Get.find<NavigationController>();
        navController.showClassDetailFromRedirect({
          'sectionId': widget.section.sectionId,
          'className': widget.section.sectionName,
          'subjectName': widget.section.subjectName,
        });
        if (mounted) {
          Navigator.of(context).maybePop();
        }
      }
    } finally {
      _isNavigating = false;
    }
  }

  Widget _buildSubmissionStatusChart(SectionDetail section) {
    final onTimeCount = section.onTimeCount;
    final lateCount = section.lateCount;
    final missingCount = section.missingCount;
    final totalCount = section.assignments.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ภาพรวมการส่งงาน',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        // Chart bars
        _buildChartBar('ตรงเวลา', onTimeCount, totalCount, Colors.green),
        const SizedBox(height: 8),
        _buildChartBar('ส่งล่าช้า', lateCount, totalCount, Colors.orange),
        const SizedBox(height: 8),
        _buildChartBar('ไม่ส่ง', missingCount, totalCount, Colors.red),
      ],
    );
  }

  Widget _buildChartBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total) : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 20,
                  color: Colors.grey[200],
                  child: Row(
                    children: [
                      Expanded(
                        flex: (percentage * 100).toInt(),
                        child: Container(
                          color: color,
                          alignment: Alignment.center,
                          child: (percentage * 100).toInt() > 20
                              ? Text(
                                  '${(percentage * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      if ((percentage * 100).toInt() <= 20)
                        Expanded(
                          flex: 100 - (percentage * 100).toInt(),
                          child: Container(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count / $total',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionDetailSheet extends StatefulWidget {
  final SectionDetail section;
  final int initialTab;

  const _SectionDetailSheet({required this.section, this.initialTab = 0});

  @override
  State<_SectionDetailSheet> createState() => _SectionDetailSheetState();
}

class _SectionDetailSheetState extends State<_SectionDetailSheet> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomSheetHeight = screenHeight * 0.75;

    return SizedBox(
      height: bottomSheetHeight,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryPalette[100],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPalette[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header - Section Name as main title
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        widget.section.subjectName,
                        style: TextStyle(
                          fontSize: 20,
                          color: AppColors.primaryPalette[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: const SizedBox(height: 16),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: const Divider(height: 20),
              ),
              // Content
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'การส่งงาน',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        _buildAssignmentList(),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Footer Button - only assignment
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context, {'action': 'assignment'});
                    },
                    icon: Icon(
                      LinkLianIcon.homework,
                      size: 16,
                    ),
                    label: const Text('ไปที่การบ้าน'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPalette[500],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentList() {
    if (widget.section.assignments.isEmpty) {
      return const Center(child: Text('ไม่มีการบ้าน'));
    }

    return Column(
      children: widget.section.assignments.map((assignment) {
        Color statusColor = Colors.grey;
        if (assignment.status == 'on_time') {
          statusColor = Colors.green;
        } else if (assignment.status == 'late') {
          statusColor = Colors.orange;
        } else if (assignment.status == 'missing') {
          statusColor = Colors.red;
        }

        // Format due date
        final dueDateStr =
          '${assignment.dueDate.day.toString().padLeft(2, '0')}/${assignment.dueDate.month.toString().padLeft(2, '0')}/${assignment.dueDate.year}';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.primaryPalette[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row with status badge on the right
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title - left side
                    Expanded(
                      child: Text(
                        assignment.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status badge - right side
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        border: Border.all(color: statusColor, width: 1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        assignment.status == 'on_time'
                            ? 'ตรงเวลา'
                            : assignment.status == 'late'
                                ? 'ส่งล่าช้า'
                                : assignment.status == 'missing'
                                    ? 'ไม่ส่ง'
                                    : 'รอการตรวจสอบ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Due date
                Text(
                  'กำหนดส่ง: $dueDateStr',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (assignment.score > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'คะแนน: ${assignment.score}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLiveList() {
    if (widget.section.lives.isEmpty) {
      return const Center(child: Text('ไม่มีไลฟ์'));
    }

    return const Center(child: Text('ไลฟ์'));
  }
}


