import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../config/app_routes.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/constants/linklian-icon.dart';
import '../../../auth/controller/auth_controller.dart';
import '../../../layout/controllers/navigation_controller.dart';
import '../../data/models/dashboard_model.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/dashboard_charts.dart';
import 'teacher_dashboard_page.dart';

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

  Widget _buildMonthSelector() {
    return Material(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Obx(
          () => DropdownButton<String>(
            value: controller.selectedMonth.value.isEmpty
                ? null
                : controller.selectedMonth.value,
            hint: const Text('เลือกเดือน'),
            isExpanded: true,
            isDense: false,
            underline: const SizedBox(),
            items: controller.availableMonths
                .toSet()
                .toList()
                .map((month) => DropdownMenuItem<String>(
                      value: month,
                      child: Text(controller.formatMonth(month)),
                    ))
                .toList(),
            onChanged: (month) {
              if (month != null) {
                controller.selectMonth(month);
                // selectMonth จะ auto-load dashboard ทำแทน
              }
            },
          ),
        ),
      ),
    );
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

class _OverviewSection extends StatelessWidget {
  final DashboardOverview overview;

  const _OverviewSection({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart 1: Summary of submissions
        DashboardCharts.submissionOverviewChart(
          title: 'ภาพรวมการส่งงาน',
          onTime: overview.onTimeTotal,
          late: overview.lateTotal,
          missing: overview.missingTotal,
        ),
        const SizedBox(height: 16),

        // Chart 2: On-time submissions by subject
        DashboardCharts.submissionBySubjectChart(
          title: 'ส่งงานตรงเวลา',
          data: {'ตรงเวลา': overview.onTimeTotal},
        ),
        const SizedBox(height: 16),

        // Chart 3: Late submissions by subject
        DashboardCharts.submissionBySubjectChart(
          title: 'ส่งงานล่าช้า',
          data: {'ล่าช้า': overview.lateTotal},
        ),

        // Overview Stats
        const SizedBox(height: 16),
        _OverviewStatsCard(overview: overview),
      ],
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

class _OverviewStatsCard extends StatelessWidget {
  final DashboardOverview overview;

  const _OverviewStatsCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'สรุปข้อมูล',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _StatRow(
              label: 'จำนวนงานทั้งหมด',
              value: '${overview.totalAssignments} งาน',
              valueColor: AppColors.primaryPalette[700]!,
            ),
            _StatRow(
              label: 'ส่งงานตรงเวลา',
              value: '${overview.onTimeTotal} งาน',
              valueColor: Colors.green,
            ),
            _StatRow(
              label: 'ส่งงานล่าช้า',
              value: '${overview.lateTotal} งาน',
              valueColor: Colors.orange,
            ),
            _StatRow(
              label: 'ไม่ส่งงาน',
              value: '${overview.missingTotal} งาน',
              valueColor: Colors.red,
            ),
            _StatRow(
              label: 'เปอร์เซ็นต์ตรงเวลา',
              value: '${overview.onTimeRate.toStringAsFixed(1)}%',
              valueColor: Colors.blue,
            ),
            _StatRow(
              label: 'บุ๊กมาร์ก',
              value: '${overview.bookmarksAdded} โพสต์',
              valueColor: AppColors.primaryPalette[700]!,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatRow({
    required this.label,
    required this.value,
    this.valueColor = const Color(0xFF1F2937), // Dark grey instead of black
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
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
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SectionDetailSheet(
        section: widget.section,
      ),
    );

    if (!mounted || result == null) {
      print('DEBUG: Bottom sheet dismissed without action');
      return;
    }

    if (result['action'] == 'assignment') {
      print('DEBUG: Received assignment action, waiting for sheet to close...');
      final authController = Get.find<AuthController>();
      final navigationController = Get.find<NavigationController>();
      
      // Wait for bottom sheet animation to complete before navigating
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!mounted) return;
      
      print('DEBUG: Navigating to ClassAssignmentPage via NavigationController');
      navigationController.showClassAssignment({
        'sectionId': widget.section.sectionId,
        'className': widget.section.sectionName,
        'subjectName': widget.section.subjectName,
        'role': authController.roleName.value,
      });
      print('DEBUG: Navigation call completed');
    }
  }

  Widget _buildAssignmentItem(
    BuildContext context,
    AssignmentData assignment,
    SectionDetail section,
  ) {
    Color statusColor = Colors.grey;
    if (assignment.status == 'on_time') {
      statusColor = Colors.green;
    } else if (assignment.status == 'late') {
      statusColor = Colors.orange;
    } else if (assignment.status == 'missing') {
      statusColor = Colors.red;
    }

    // Format due date
    final dueDateStr = assignment.dueDate.day.toString().padLeft(2, '0') +
        '/' +
        assignment.dueDate.month.toString().padLeft(2, '0') +
        '/' +
        assignment.dueDate.year.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
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
            'ส่งด้วย: $dueDateStr',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
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

  const _SectionDetailSheet({required this.section});

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
                      // Text(
                      //   widget.section.sectionName,
                      //   style: TextStyle(
                      //     fontSize: 24,
                      //     fontWeight: FontWeight.w700,
                      //     color: AppColors.primaryPalette[700],
                      //   ),
                      // ),
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
              const SizedBox(height: 16),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: SingleChildScrollView(
                    child: _buildAssignmentList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Footer Button
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      print('[BottomSheet] Button tapped - closing sheet');
                      Navigator.of(context).pop({'action': 'assignment'});
                      print('[BottomSheet] Sheet close initiated');
                    },
                    icon: Icon(
                      LinkLianIcon.homework,
                      size: 16,
                    ),
                    label: const Text(
                      'ไปที่การบ้าน',
                    ),
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
        final dueDateStr = assignment.dueDate.day.toString().padLeft(2, '0') +
            '/' +
            assignment.dueDate.month.toString().padLeft(2, '0') +
            '/' +
            assignment.dueDate.year.toString();

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
                  'ส่งด้วย: $dueDateStr',
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
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentSectionCardCompact extends StatelessWidget {
  final SectionDetail section;

  const _StudentSectionCardCompact({required this.section});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        try {
          // Navigate to class detail page to view assignments
          if (Get.isRegistered<NavigationController>()) {
            final navController = Get.find<NavigationController>();
            final args = {
              'sectionId': section.sectionId,
              'sectionName': section.subjectName,
            };
            print('[Dashboard] Compact section card tapped: $args');
            navController.showClassDetail(args);
          } else {
            print('[Dashboard] ERROR: NavigationController not registered in compact');
          }
        } catch (e) {
          print('[Dashboard] ERROR tapping compact section card: $e');
        }
      },
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject Name as main title - compact
              Text(
                section.subjectName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Assignment count - compact
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: section.assignments.isEmpty
                      ? Colors.grey[200]
                      : AppColors.primaryPalette[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LinkLianIcon.fileDescription,
                      size: 14,
                      color: section.assignments.isEmpty
                          ? Colors.grey[600]
                          : AppColors.primaryPalette[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      section.assignments.isEmpty
                          ? 'ไม่มี'
                          : '${section.assignments.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: section.assignments.isEmpty
                            ? Colors.grey[600]
                            : AppColors.primaryPalette[700],
                      ),
                    ),
                  ],
                ),
              ),
              if (section.assignments.isNotEmpty) ...[
                const SizedBox(height: 10),
                // Compact submission chart
                _buildCompactSubmissionChart(section),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSubmissionChart(SectionDetail section) {
    final onTimeCount = section.onTimeCount;
    final lateCount = section.lateCount;
    final missingCount = section.missingCount;
    final totalCount = section.assignments.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ส่งงาน',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        // Compact bar chart
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Container(
            height: 12,
            color: Colors.grey[200],
            child: Row(
              children: [
                // On-time segment
                Expanded(
                  flex: onTimeCount,
                  child: Container(color: Colors.green),
                ),
                // Late segment
                Expanded(
                  flex: lateCount,
                  child: Container(color: Colors.orange),
                ),
                // Missing segment
                Expanded(
                  flex: missingCount,
                  child: Container(color: Colors.red),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _compactLegend('ตรง', onTimeCount, Colors.green),
            _compactLegend('ล่าช้า', lateCount, Colors.orange),
            _compactLegend('ไม่ส่ง', missingCount, Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _compactLegend(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          '$label $count',
          style: const TextStyle(fontSize: 9),
        ),
      ],
    );
  }
}

class _StudentSectionDetailSheet extends StatefulWidget {
  final SectionDetail section;

  const _StudentSectionDetailSheet({required this.section});

  @override
  State<_StudentSectionDetailSheet> createState() =>
      _StudentSectionDetailSheetState();
}

class _StudentSectionDetailSheetState extends State<_StudentSectionDetailSheet> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.section.subjectName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Submission Status Chart
              _buildSubmissionChart(widget.section.assignments),
              const SizedBox(height: 24),

              // Score Chart
              if (_hasScores(widget.section.assignments)) ...[
                _buildScoreChart(widget.section.assignments),
                const SizedBox(height: 24),
              ],

              // Assignments
              Text(
                'งานที่มอบหมาย (${widget.section.assignments.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (widget.section.assignments.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          LinkLianIcon.fileDescription,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ไม่มีงานในเดือนนี้',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...widget.section.assignments.map((assignment) {
                  final statusColor = _getStatusColor(assignment.status);
                  final statusLabel = _getStatusLabel(assignment.status);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withAlpha(30),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  assignment.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'กำหนดส่ง: ${assignment.dueDate.toString().split(' ')[0]}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (assignment.score > 0)
                                Text(
                                  'คะแนน: ${assignment.score}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'on_time':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'missing':
        return Colors.red;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'on_time':
        return 'ตรงเวลา';
      case 'late':
        return 'ล่าช้า';
      case 'missing':
        return 'ไม่ส่ง';
      case 'pending':
        return 'รอส่ง';
      default:
        return 'ไม่ทราบ';
    }
  }

  bool _hasScores(List<AssignmentData> assignments) {
    return assignments.any((a) => a.score > 0);
  }

  Widget _buildSubmissionChart(List<AssignmentData> assignments) {
    final onTime = assignments.where((a) => a.status == 'on_time').length;
    final late = assignments.where((a) => a.status == 'late').length;
    final missing = assignments.where((a) => a.status == 'missing').length;
    final total = assignments.length;

    final items = [
      ('งานทั้งหมด', total, AppColors.primaryPalette[700]!),
      ('ตรงเวลา', onTime, Colors.green),
      ('ล่าช้า', late, Colors.orange),
      ('ไม่ส่ง', missing, Colors.red),
    ];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'สัญแสดงการส่ง',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.map((item) {
                final (label, value, color) = item;
                final height = total > 0 ? (value / total) * 100 : 0.0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: height + 10,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                          child: Center(
                            child: height > 20
                                ? Text(
                                    value.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  )
                                : const SizedBox(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          style: const TextStyle(fontSize: 11),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreChart(List<AssignmentData> assignments) {
    final submittedAssignments =
        assignments.where((a) => a.score > 0).toList();

    if (submittedAssignments.isEmpty) {
      return const SizedBox();
    }

    final scores = submittedAssignments.map((a) => a.score).toList();
    final avgScore =
        scores.isNotEmpty ? scores.reduce((a, b) => a + b) / scores.length : 0;
    final maxScore = scores.isNotEmpty ? scores.reduce((a, b) => a > b ? a : b) : 0;
    final minScore = scores.isNotEmpty ? scores.reduce((a, b) => a < b ? a : b) : 0;

    // Group scores by range
    final scoreRanges = {
      '80-100': scores.where((s) => s >= 80).length,
      '60-79': scores.where((s) => s >= 60 && s < 80).length,
      '40-59': scores.where((s) => s >= 40 && s < 60).length,
      '0-39': scores.where((s) => s < 40).length,
    };

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'สัญแสดงคะแนน',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreStat('เฉลี่ย', avgScore.toStringAsFixed(1), Colors.blue),
                _buildScoreStat('สูงสุด', maxScore.toString(), Colors.green),
                _buildScoreStat('ต่ำสุด', minScore.toString(), Colors.red),
              ],
            ),
            const SizedBox(height: 24),
            // Score range chart
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: scoreRanges.entries.map((entry) {
                final (range, count) = (entry.key, entry.value);
                final height = submittedAssignments.isNotEmpty
                    ? (count / submittedAssignments.length) * 80
                    : 0.0;

                final barColor = range == '80-100'
                    ? Colors.green
                    : range == '60-79'
                        ? Colors.blue
                        : range == '40-59'
                            ? Colors.orange
                            : Colors.red;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: height + 10,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                          child: Center(
                            child: height > 20
                                ? Text(
                                    count.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  )
                                : const SizedBox(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          range,
                          style: const TextStyle(fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

