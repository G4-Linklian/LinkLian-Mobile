import 'package:LinkLian/core/constants/colors.dart';
import 'package:flutter/material.dart';

class QuizResultPage extends StatelessWidget {
  final int correct;
  final int total;
  final VoidCallback onReview;
  final VoidCallback onBackToList;

  const QuizResultPage({
    super.key,
    required this.correct,
    required this.total,
    required this.onReview,
    required this.onBackToList,
  });

  @override
  Widget build(BuildContext context) {
    final wrong = total - correct;
    final percent = total > 0 ? (correct / total * 100) : 0.0;
    final percentText = percent.toStringAsFixed(0);

    // Determine feedback tier
    final Color scoreColor;
    final String feedbackText;
    final Color feedbackBg;
    if (percent >= 80) {
      scoreColor = AppColors.successPalette[600]!;
      feedbackBg = AppColors.successPalette[100]!;
      feedbackText = 'ยอดเยี่ยม!';
    } else if (percent >= 50) {
      scoreColor = AppColors.primaryPalette[600]!;
      feedbackBg = AppColors.primaryPalette[100]!;
      feedbackText = 'ทำได้ดี!';
    } else {
      scoreColor = AppColors.dangerPalette[500]!;
      feedbackBg = AppColors.dangerPalette[200]!;
      feedbackText = 'ลองใหม่อีกครั้ง';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'ผลการทำแบบทดสอบ',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 24),

            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: scoreColor.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: scoreColor, width: 4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$percentText%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                  Text(
                    '$correct / $total ข้อ',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.black.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: feedbackBg,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                feedbackText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: scoreColor,
                ),
              ),
            ),

            const SizedBox(height: 28),

            Row(
              children: [
                Expanded(
                  child: _statCard(
                    label: 'ถูก',
                    count: correct,
                    icon: Icons.check_circle_outline,
                    color: AppColors.successPalette[600]!,
                    bg: AppColors.successPalette[100]!,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    label: 'ผิด',
                    count: wrong,
                    icon: Icons.cancel_outlined,
                    color: AppColors.dangerPalette[500]!,
                    bg: AppColors.dangerPalette[200]!,
                  ),
                ),
              ],
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPalette[500],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onReview,
                child: const Text(
                  'ทบทวนแบบทดสอบ',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primaryPalette[500]!),
                  foregroundColor: AppColors.primaryPalette[600],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onBackToList,
                child: const Text(
                  'กลับหน้ารวมแบบทดสอบ',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
