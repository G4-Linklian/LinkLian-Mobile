import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/data/model/semester_model.dart';
import '../controllers/class_feed_controller.dart';

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
        itemBuilder: (context) {
          return semesters.map((SemesterModel s) {
            return PopupMenuItem<int>(
              value: s.semesterId,
              child: Text(s.semester),
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