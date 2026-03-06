import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/data/model/semester_model.dart';
import '../controllers/class_feed_controller.dart';
import '../../../../core/constants/colors.dart';

class SemesterSelector extends StatelessWidget {
  const SemesterSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ClassFeedController>();

    return Obx(() {
      final selectedId = controller.selectedSemesterId.value;
      final semesters = controller.semesters;

      if (selectedId == null || semesters.isEmpty) {
        return const SizedBox();
      }

      final selectedSemester =
          semesters.firstWhere((s) => s.semesterId == selectedId);

      return PopupMenuButton<int>(
        onSelected: controller.changeSemester,
        offset: const Offset(0, 40), // แสดง menu ด้านล่างปุ่ม 40px
        itemBuilder: (context) {
          // Sort semesters by year then term (e.g., 1/2567, 2/2567, 1/2568...)
          final sortedSemesters = List<SemesterModel>.from(semesters)
            ..sort((a, b) {
              // Parse year and term from semester string (e.g., "2/2568")
              final partsA = a.semester.split('/');
              final partsB = b.semester.split('/');
              
              final yearA = int.tryParse(partsA.length > 1 ? partsA[1] : '0') ?? 0;
              final yearB = int.tryParse(partsB.length > 1 ? partsB[1] : '0') ?? 0;
              final termA = int.tryParse(partsA.isNotEmpty ? partsA[0] : '0') ?? 0;
              final termB = int.tryParse(partsB.isNotEmpty ? partsB[0] : '0') ?? 0;
              
              // Sort by year first, then by term
              if (yearA != yearB) {
                return yearA.compareTo(yearB);
              }
              return termA.compareTo(termB);
            });

          // Debug: print sorted order
          debugPrint('📅 Sorted semesters: ${sortedSemesters.map((s) => s.semester).toList()}');

          return sortedSemesters.map((SemesterModel s) {
            final isOpen = s.status == 'open';
            final isSelected = s.semesterId == selectedId;

            return PopupMenuItem<int>(
              value: s.semesterId,
              child: Center(
                child: Text(
                  s.semester,
                  style: TextStyle(
                    fontWeight: isOpen ? FontWeight.bold : FontWeight.normal,
                    color: isOpen 
                      ? AppColors.primaryPalette[700] 
                      : (isSelected ? AppColors.primaryPalette[500] : Colors.black),
                  ),
                ),
              ),
            );
          }).toList();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFCFA3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Text(
                selectedSemester.semester,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.filter_list, size: 16),
            ],
          ),
        ),
      );
    });
  }
}