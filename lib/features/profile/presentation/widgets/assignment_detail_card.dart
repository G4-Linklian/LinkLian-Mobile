import 'package:LinkLian/core/utils/logger.dart';
import 'package:flutter/material.dart';
import '../../../auth/controller/auth_controller.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/linklian-icon.dart';
import '../../data/models/dashboard_model.dart';
import 'package:get/get.dart';
import '../../../layout/controllers/navigation_controller.dart';

class SectionDetailCard extends StatefulWidget {
  final SectionDetail section;
  final VoidCallback? onTap;

  const SectionDetailCard({super.key, required this.section, this.onTap});

  @override
  State<SectionDetailCard> createState() => _SectionDetailCardState();
}

class _SectionDetailCardState extends State<SectionDetailCard> {
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
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Section name and subject
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.section.sectionName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.section.subjectName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Stats: Assignments and Lives
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openSectionSheet(),
                      child: _CompactStatItem(
                        icon: LinkLianIcon.fileDescription,
                        label: 'งาน',
                        value: widget.section.assignments.length,
                        color: AppColors.primaryPalette[600]!,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openSectionSheet(initialTab: 1),
                      child: _CompactStatItem(
                        icon: LinkLianIcon.broadcast,
                        label: 'ไลฟ์',
                        value: widget.section.lives.length,
                        color: AppColors.primaryPalette[700]!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSectionSheet({int initialTab = 0}) async {
    if (_isNavigating) return;
    
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _SectionDetailSheet(section: widget.section, initialTab: initialTab),
    );

    if (!mounted || result == null) {
      return;
    }

    if (_isNavigating) return;
    _isNavigating = true;

    try {
      if (result['action'] == 'assignment') {
        final authController = Get.find<AuthController>();
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
}

class _CompactStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _CompactStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            value.toString(),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
  late int _selectedTabIndex;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTab;
  }

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
                      Text(
                        widget.section.sectionName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryPalette[700],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.section.subjectName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
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
              // Tabs
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTabIndex = 0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LinkLianIcon.fileDescription,
                                  size: 16,
                                  color: AppColors.primaryPalette[700],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'การส่งงาน',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryPalette[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 2,
                              color: _selectedTabIndex == 0
                                  ? AppColors.primaryPalette[400]
                                  : Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTabIndex = 1),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LinkLianIcon.broadcast,
                                  size: 16,
                                  color: AppColors.primaryPalette[700],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ไลฟ์และคำถาม',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryPalette[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 2,
                              color: _selectedTabIndex == 1
                                  ? AppColors.primaryPalette[400]
                                  : Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: SingleChildScrollView(
                    child: _selectedTabIndex == 0
                        ? _buildAssignmentList()
                        : _buildLiveList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Footer Button - changes based on tab
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_selectedTabIndex == 0) {
                        // Tab 0: Assignment - Go to Class Assignment page
                        Navigator.pop(context, {'action': 'assignment'});
                      } else if (_selectedTabIndex == 1) {
                        // Tab 1: Lives - Go to Class Detail page
                        Navigator.pop(context, {'action': 'class_detail'});
                      }
                    },
                    icon: Icon(
                      _selectedTabIndex == 0
                          ? LinkLianIcon.homework
                          : LinkLianIcon.classroom,
                      size: 16,
                    ),
                    label: Text(
                      _selectedTabIndex == 0
                          ? 'ไปที่การบ้าน'
                          : 'ไปที่ห้องเรียน',
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
                Text(
                  assignment.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatBadge(
                      label: 'ตรงเวลา',
                      value: assignment.onTimeCount,
                      color: Colors.green,
                    ),
                    _StatBadge(
                      label: 'ส่งช้า',
                      value: assignment.lateCount,
                      color: Colors.orange,
                    ),
                    _StatBadge(
                      label: 'ไม่ส่ง',
                      value: assignment.missingCount,
                      color: Colors.red,
                    ),
                  ],
                ),
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

    return Column(
      children: widget.section.lives.map((live) {
        return GestureDetector(
          onTap: () {
            if (Get.currentRoute == '/live-history') {
              Get.offNamed(
                '/live',
                arguments: {
                  'qaLiveId': live.liveId,
                  'sectionId': widget.section.sectionId,
                  'isHistoryMode': true,
                },
              );
            } else {
              Get.offNamed(
                '/live-history',
                arguments: {'sectionId': widget.section.sectionId},
              );

              Future.delayed(const Duration(milliseconds: 500), () {
                if (Get.currentRoute == '/live-history') {
                  Get.toNamed(
                    '/live',
                    arguments: {
                      'qaLiveId': live.liveId,
                      'sectionId': widget.section.sectionId,
                      'isHistoryMode': true,
                    },
                  );
                }
              });
            }
          },
          child: Padding(
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
                  // Live Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryPalette[700]!.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          LinkLianIcon.broadcast,
                          color: AppColors.primaryPalette[700],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    live.title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Builder(
                              builder: (context) {
                                final displayDuration =
                                    formatSecondsToHourMinute(
                                      live.duration * 60,
                                    );
                                appLog.debug(
                                  '[AssignmentDetailCard] Live: ${live.title} | duration in model: ${live.duration} minutes | formatted: $displayDuration',
                                );
                                return Text(
                                  'วันที่ ${live.liveDate.day}/${live.liveDate.month}/${live.liveDate.year} | ความยาว: $displayDuration',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                );
                              },
                            ),
                            if (live.totalQuestions > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'คำถาม: ${live.totalQuestions} ข้อ',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Files Section
                  if (live.topQuestionedFiles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Text(
                      'ไฟล์คำถาม',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: live.topQuestionedFiles.map((file) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withAlpha(15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.amber.withAlpha(50),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.description,
                                  size: 16,
                                  color: Colors.amber.shade600,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        file.attachmentName,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (file.topPages.isNotEmpty)
                                        Text(
                                          'หน้า: ${file.topPages.join(', ')}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
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
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
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
