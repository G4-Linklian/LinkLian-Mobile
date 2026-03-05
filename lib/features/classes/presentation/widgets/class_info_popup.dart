import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/colors.dart';
import '../controllers/class_info_controller.dart';
import '../../../../core/utils/formatter.dart';

class ClassInfoPopup extends StatefulWidget {
  final int sectionId;

  const ClassInfoPopup({super.key, required this.sectionId});

  @override
  State<ClassInfoPopup> createState() => _ClassInfoPopupState();
}

class _ClassInfoPopupState extends State<ClassInfoPopup> {
  late final ClassInfoController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      ClassInfoController(sectionId: widget.sectionId),
      tag: 'class_info_${widget.sectionId}',
    );
  }

  @override
  void dispose() {
    Get.delete<ClassInfoController>(tag: 'class_info_${widget.sectionId}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppColors.primaryPalette[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.primaryPalette[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Content
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.error.value.isNotEmpty) {
                return Center(
                  child: Text(
                    controller.error.value,
                    style: TextStyle(color: AppColors.dangerPalette[500]),
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('สถานที่'),
                    const SizedBox(height: 8),
                    _buildLocationSection(controller),
                    const SizedBox(height: 20),

                    _buildSectionTitle('ตารางเรียน'),
                    const SizedBox(height: 8),
                    _buildScheduleSection(controller),
                    const SizedBox(height: 20),

                    _buildSectionTitle('สมาชิก'),
                    const SizedBox(height: 8),
                    _buildMemberSection(controller),
                    const SizedBox(height: 20),

                    _buildSectionTitle('ผู้สอน'),
                    const SizedBox(height: 8),
                    _buildEducatorSection(controller),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryPalette[900],
      ),
    );
  }

  Widget _buildLocationSection(ClassInfoController controller) {
    return Obx(() {
      final locations = controller.uniqueLocations;

      if (locations.isEmpty) {
        return Text(
          'ไม่ระบุ',
          style: TextStyle(fontSize: 14, color: AppColors.primaryPalette[800]),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: locations.map((location) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppColors.primaryPalette[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryPalette[800],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildScheduleSection(ClassInfoController controller) {
    return Obx(() {
      if (controller.schedules.isEmpty) {
        return Text(
          'ไม่มีตารางเรียน',
          style: TextStyle(fontSize: 14, color: AppColors.primaryPalette[600]),
        );
      }

      return Column(
        children: controller.schedules.map((schedule) {
          return _buildScheduleItem(controller, schedule);
        }).toList(),
      );
    });
  }

  Widget _buildScheduleItem(
    ClassInfoController controller,
    Map<String, dynamic> schedule,
  ) {
    final dayOfWeek = Formatter.dayOfWeekToText(schedule['day_of_week']);
    final startTime = controller.formatTime(schedule['start_time'] ?? '');
    final endTime = controller.formatTime(schedule['end_time'] ?? '');
    final room = schedule['room'] as Map<String, dynamic>?;
    final building = schedule['building'] as Map<String, dynamic>?;
    final roomNumber = room?['room_number'] ?? '';
    final buildingName = building?['building_name'] ?? '';

    final locationText = [
      if (buildingName.isNotEmpty) buildingName,
      if (roomNumber.isNotEmpty) 'ห้อง $roomNumber',
    ].join(' ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 16, color: AppColors.primaryPalette[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$dayOfWeek $startTime - $endTime${locationText.isNotEmpty ? ' ($locationText)' : ''}',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primaryPalette[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberSection(ClassInfoController controller) {
    final scrollController = ScrollController();

    return Obx(() {
      if (controller.members.isEmpty) {
        return Text(
          'ไม่มีสมาชิก',
          style: TextStyle(fontSize: 14, color: AppColors.primaryPalette[600]),
        );
      }

      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 200),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primaryPalette[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Scrollbar(
            controller: scrollController,
            thumbVisibility: true,
            child: ListView.builder(
              controller: scrollController,
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: controller.members.length,
              itemBuilder: (context, index) {
                final member = controller.members[index];
                return _buildMemberItem(index + 1, member);
              },
            ),
          ),
        ),
      );
    });
  }

  Widget _buildMemberItem(int index, Map<String, dynamic> member) {
    final studentCode = member['student_code']?.toString() ?? '';
    final displayName = member['display_name'] ?? 'ไม่ระบุชื่อ';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Text(
            '$index.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primaryPalette[700],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryPalette[800],
                  ),
                ),
                if (studentCode.isNotEmpty)
                  Text(
                    'รหัส: $studentCode',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryPalette[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducatorSection(ClassInfoController controller) {
    return Obx(() {
      if (controller.educators.isEmpty) {
        return Text(
          'ไม่มีข้อมูลผู้สอน',
          style: TextStyle(fontSize: 14, color: AppColors.primaryPalette[600]),
        );
      }

      return Column(
        children: controller.educators.map((educator) {
          return _buildEducatorItem(educator);
        }).toList(),
      );
    });
  }

  Widget _buildEducatorItem(Map<String, dynamic> educator) {
    final displayName = educator['display_name'] ?? 'ไม่ระบุชื่อ';
    final profilePic = educator['profile_pic'] as String?;
    final isMainTeacher = educator['is_main_teacher'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryPalette[200],
            backgroundImage: profilePic != null && profilePic.isNotEmpty
                ? NetworkImage(profilePic)
                : null,
            child: profilePic == null || profilePic.isEmpty
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryPalette[700],
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryPalette[800],
              ),
            ),
          ),
          if (isMainTeacher)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryPalette[200],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'ครูผู้สอนหลัก',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryPalette[700],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
