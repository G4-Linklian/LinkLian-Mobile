import 'package:LinkLian/core/constants/linklian-icon.dart';
import 'package:flutter/material.dart';
import '../../../data/model/teaching_schedule_model.dart';

class DayScheduleSection extends StatelessWidget {
  final int dayOfWeek;
  final List<TeachingScheduleModel> schedules;
  final bool isLast;

  const DayScheduleSection({
    super.key,
    required this.dayOfWeek,
    required this.schedules,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final sortedSchedules = [...schedules]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final color = dayColor(dayOfWeek);
    final dayName = _getDayName(dayOfWeek);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              dayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: sortedSchedules.map((s) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  // border: Border.all(color: Colors.grey.shade200),
                  border: Border.all(color: color.withOpacity(0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.subjectName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),

                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${_formatTime(s.startTime)} - ${_formatTime(s.endTime)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                s.className != null ? '${s.className}' : '-',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          Row(
                            children: [
                              const Icon(
                                LinkLianIcon.location,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _locationText(s),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        // if (!isLast)
        //   Padding(
        //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        //     child: Divider(
        //       height: 1,
        //       thickness: 2,
        //       color: Colors.grey.shade300,
        //     ),
        //   ),
      ],
    );
  }

  String _locationText(TeachingScheduleModel e) {
    if (e.building != null && e.building!.isNotEmpty) {
      return e.building!;
    }
    return '-';
  }

  String _getDayName(int day) {
    const days = {
      1: 'วันจันทร์',
      2: 'วันอังคาร',
      3: 'วันพุธ',
      4: 'วันพฤหัสบดี',
      5: 'วันศุกร์',
      6: 'วันเสาร์',
      7: 'วันอาทิตย์',
    };
    return days[day] ?? '';
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return time;

    final hour = parts[0].padLeft(2, '0');
    final minute = parts[1].padLeft(2, '0');

    return '$hour:$minute';
  }
}

/// สีประจำวัน
Color dayColor(int day) {
  switch (day) {
    case 1:
      return Colors.yellow.shade700;
    case 2:
      return Colors.pink.shade300;
    case 3:
      return Colors.green.shade400;
    case 4:
      return Colors.orange.shade400;
    case 5:
      return Colors.blue.shade400;
    case 6:
      return Colors.purple.shade300;
    case 7:
      return Colors.red.shade400;
    default:
      return Colors.grey;
  }
}
