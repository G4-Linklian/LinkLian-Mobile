import 'package:flutter/material.dart';

class DashboardCharts {
  /// Chart 1: Overview of submission status (On-time, Late, Missing)
  static Widget submissionOverviewChart({
    required String title,
    required int onTime,
    required int late,
    required int missing,
  }) {
    final total = onTime + late + missing;
    final items = [
      ('ตรงเวลา', onTime, Colors.green),
      ('ส่งช้า', late, Colors.orange),
      ('ไม่ส่ง', missing, Colors.red),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Simple bar chart
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.map((item) {
                final (label, value, color) = item;
                final height =
                    total > 0 ? (value / total) * 120 : 0.0;

                return Column(
                  children: [
                    Container(
                      width: 40,
                      height: height,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      '$value',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Chart 2 & 3: Submissions by subject
  static Widget submissionBySubjectChart({
    required String title,
    required Map<String, int> data,
  }) {
    final maxValue =
        data.values.isEmpty ? 1 : data.values.reduce((a, b) => a > b ? a : b);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Horizontal bar chart
            ...data.entries.map((entry) {
              final percentage = maxValue > 0 ? (entry.value / maxValue) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage,
                              minHeight: 24,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFFFA500),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${entry.value}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                )
              );
            }),
          ],
        ),
      ),
    );
  }
}
