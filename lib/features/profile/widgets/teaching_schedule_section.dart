import 'package:flutter/material.dart';
import '../../../data/model/teaching_schedule_model.dart';
import 'day_schedule_section.dart';

class TeachingScheduleSection extends StatelessWidget {
  final List<TeachingScheduleModel> schedules;
  const TeachingScheduleSection({super.key, required this.schedules});

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'ไม่มีตารางสอน',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    // group ตามวัน
    final Map<int, List<TeachingScheduleModel>> grouped = {};
    for (final s in schedules) {
      grouped.putIfAbsent(s.dayOfWeek, () => []).add(s);
    }

    for (final list in grouped.values) {
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'ตารางสอน',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: List.generate(7, (index) {
              final day = index + 1;
              final daySchedules = grouped[day];
              if (daySchedules == null || daySchedules.isEmpty) {
                return const SizedBox();
              }
              return DayScheduleSection(
                dayOfWeek: day,
                schedules: daySchedules,
                isLast: _isLastDay(grouped, day),
              );
            }),
          ),
        ),
      ),
      ],
    );
  }
   

  bool _isLastDay(Map<int, List<TeachingScheduleModel>> grouped, int currentDay) {
    final daysWithSchedules = grouped.keys.where((k) => grouped[k]!.isNotEmpty).toList();
    if (daysWithSchedules.isEmpty) return true;
    return currentDay == daysWithSchedules.last;
  }
}