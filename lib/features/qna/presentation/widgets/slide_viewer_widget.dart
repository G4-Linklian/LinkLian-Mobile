import 'package:LinkLian/core/utils/logger.dart';
import 'package:LinkLian/features/qna/presentation/controllers/live_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';

class SlideViewerWidget extends StatelessWidget {
  final LiveController controller;

  const SlideViewerWidget({
    super.key,
    required this.controller,
  });

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      controller.pdfRebuildToken.value;
      final attachment = controller.selectedAttachment.value;

      if (attachment == null) {
        appLog.debug('SlideViewerWidget - attachment is null', actionPage: 'SlideViewerWidget.build');
        return const Center(child: Text('No slide selected'));
      }

      final selectedAttachmentId = _toInt(attachment['attachment_id']);
      final selectedUrl = attachment['file_url']?.toString().trim() ?? '';
      final canonicalAttachment = selectedAttachmentId != null
          ? controller.resolveAttachmentById(selectedAttachmentId)
          : null;

      final effectiveAttachment =
          selectedUrl.isNotEmpty
              ? Map<String, dynamic>.from(attachment)
              : (canonicalAttachment != null
                    ? Map<String, dynamic>.from(canonicalAttachment)
                    : Map<String, dynamic>.from(attachment));

      final fileUrl = effectiveAttachment['file_url']?.toString().trim() ?? '';
      final fileType = effectiveAttachment['file_type']?.toString() ?? '';
      final renderedAttachmentId = _toInt(effectiveAttachment['attachment_id']);

      if (selectedAttachmentId != renderedAttachmentId) {
        appLog.debug('SlideViewerWidget - attachment ID mismatch', actionPage: 'SlideViewerWidget.build', data: {
          'selected': selectedAttachmentId,
          'rendered': renderedAttachmentId
        });
      }

      appLog.debug('SlideViewerWidget - building slide area', actionPage: 'SlideViewerWidget.build', data: {
        'attachment_id': effectiveAttachment['attachment_id'],
        'file_url': fileUrl,
        'file_type': fileType
      });

      if (fileUrl.isEmpty) {
        final resolved = controller.resolveAttachmentById(
          attachment['attachment_id'],
        );
        final resolvedUrl = resolved?['file_url']?.toString().trim() ?? '';
        if (resolved != null && resolvedUrl.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.selectedAttachment.value =
                Map<String, dynamic>.from(resolved);
          });
          return const Center(child: CircularProgressIndicator());
        }

        appLog.debug('SlideViewerWidget - file_url is empty', actionPage: 'SlideViewerWidget.build', data: {'attachment': attachment});
        return const Center(child: Text('Slide url unavailable'));
      }

      if (fileType.contains('image')) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              boundaryMargin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Image.network(fileUrl, fit: BoxFit.contain),
            ),
          ),
        );
      }

      if (fileType.contains('pdf')) {
        final attachmentId = _toInt(effectiveAttachment['attachment_id']) ?? 0;
        final rebuildToken = controller.pdfRebuildToken.value;
        return FutureBuilder<String?>(
          key: ValueKey('pdf_builder_${attachmentId}_${fileUrl}_$rebuildToken'),
          future: controller.downloadPdf(
            fileUrl,
            attachmentId: attachmentId,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final path = snapshot.data;
            if (path == null) {
              return const Center(child: Text('Failed to load PDF'));
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: PDFView(
                  key: ValueKey('pdf_view_${attachmentId}_$fileUrl'),
                  filePath: path,
                  enableSwipe: true,
                  swipeHorizontal: true,
                  fitPolicy: FitPolicy.BOTH,
                  onViewCreated: (pdf) {
                    appLog.debug('SlideViewerWidget - PDFView onViewCreated - Setting pdfController', actionPage: 'SlideViewerWidget.build');
                    controller.pdfController.value = pdf;
                    appLog.debug('SlideViewerWidget - PDFView onViewCreated - Calling applyCurrentPageToPdf', actionPage: 'SlideViewerWidget.build', data: {'currentPage': controller.currentPage.value});
                    controller.applyCurrentPageToPdf();
                  },
                  onRender: (pages) {
                    appLog.debug('SlideViewerWidget - PDFView onRender - pages=$pages', actionPage: 'SlideViewerWidget.build');
                    controller.totalPages.value = pages ?? 0;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      appLog.debug('SlideViewerWidget - After render frame - applying pending page', actionPage: 'SlideViewerWidget.build');
                      controller.applyCurrentPageToPdf();
                    });
                  },
                  onPageChanged: (page, total) {
                    final current = page ?? 0;
                    controller.onPdfPageChanged(current);
                  },
                ),
              ),
            );
          },
        );
      }

      return const Center(child: Text('Unsupported file type'));
    });
  }
}
