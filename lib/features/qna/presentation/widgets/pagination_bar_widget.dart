import 'package:LinkLian/core/constants/colors.dart';
import 'package:LinkLian/features/qna/presentation/controllers/live_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaginationBarWidget extends StatelessWidget {
  final LiveController controller;

  const PaginationBarWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Obx(() {
        final currentPage = controller.currentPage.value;
        final totalPages = controller.totalPages.value;
        final currentDisplay = totalPages > 0 ? currentPage + 1 : 0;
        final canGoPrev = currentPage > 0;
        final canGoNext = totalPages > 0 && currentPage < totalPages - 1;

        final windowSize = 5;
        var start = currentPage - 2;
        if (start < 0) start = 0;
        var end = start + windowSize;
        if (end > totalPages) {
          end = totalPages;
          start = (end - windowSize).clamp(0, end);
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNavButton(
              icon: Icons.chevron_left,
              enabled: canGoPrev,
              onTap: () async {
                if (!canGoPrev) return;
                await controller.pdfController.value?.setPage(currentPage - 1);
              },
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                for (var page = start; page < end; page++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: page == currentPage ? 24 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: page == currentPage
                          ? AppColors.primaryPalette[500]
                          : const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            _buildNavButton(
              icon: Icons.chevron_right,
              enabled: canGoNext,
              onTap: () async {
                if (!canGoNext) return;
                await controller.pdfController.value?.setPage(currentPage + 1);
              },
            ),
            const SizedBox(width: 14),
            Text(
              '$currentDisplay/$totalPages',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? Colors.white : const Color(0xFFF3F4F6),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? const Color(0xFF374151) : const Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}
