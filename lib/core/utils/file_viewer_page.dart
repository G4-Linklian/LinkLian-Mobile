import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/colors.dart';
import '../constants/linklian-icon.dart';

/// Shared fullscreen file viewer page.
/// Supports: PDF, images (jpg/jpeg/png/webp/gif), links, and unsupported types.
class FileViewerPage extends StatefulWidget {
  final String fileUrl;
  final String fileName;
  final String fileType;

  const FileViewerPage({
    super.key,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
  });

  /// Navigate to viewer via Get.to
  static void open({
    required String fileUrl,
    required String fileName,
    required String fileType,
  }) {
    Get.to(
      () => FileViewerPage(
        fileUrl: fileUrl,
        fileName: fileName,
        fileType: fileType,
      ),
      transition: Transition.fadeIn,
      fullscreenDialog: true,
    );
  }

  @override
  State<FileViewerPage> createState() => _FileViewerPageState();
}

class _FileViewerPageState extends State<FileViewerPage> {
  String? _localPdfPath;
  bool _isPdfLoading = false;
  bool _pdfLoadFailed = false;
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    if (_isPdf(widget.fileType)) {
      _loadPdf(widget.fileUrl);
    }
    if (_isLink(widget.fileType)) {
      _openLink(widget.fileUrl);
    }
  }

  bool _isImage(String type) {
    final t = type.toLowerCase();
    return t == 'jpg' ||
        t == 'jpeg' ||
        t == 'png' ||
        t == 'gif' ||
        t == 'webp' ||
        t.contains('image');
  }

  bool _isPdf(String type) {
    final t = type.toLowerCase();
    return t == 'pdf' || t.contains('pdf');
  }

  bool _isLink(String type) {
    return type.toLowerCase() == 'link';
  }

  Future<void> _loadPdf(String url) async {
    if (!mounted) return;
    setState(() {
      _isPdfLoading = true;
      _pdfLoadFailed = false;
    });

    try {
      final fileName = url.split('/').last.split('?').first;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');

      if (!await file.exists()) {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}');
        }
        await file.writeAsBytes(response.bodyBytes);
      }

      if (mounted) {
        setState(() {
          _localPdfPath = file.path;
          _isPdfLoading = false;
        });
      }
    } catch (e) {
      debugPrint('PDF download error: $e');
      if (mounted) {
        setState(() {
          _isPdfLoading = false;
          _pdfLoadFailed = true;
        });
      }
    }
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      Get.back();
      return;
    }
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
      } catch (_) {}
    }
    // Close viewer after opening link in browser
    if (mounted) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryPalette[200],
      appBar: AppBar(
        backgroundColor:
            AppColors.primaryPalette[500]!.withValues(alpha: 0.8),
        leading: IconButton(
          icon: Icon(LinkLianIcon.close, color: AppColors.dangerPalette[700]),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.fileName,
          style: TextStyle(color: AppColors.primaryPalette[900], fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_isPdf(widget.fileType) && _totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${_currentPage + 1}/$_totalPages',
                  style: TextStyle(
                    color: AppColors.primaryPalette[900],
                    fontSize: 15,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLink(widget.fileType)) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isImage(widget.fileType)) {
      return Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            widget.fileUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                _buildErrorState('ไม่สามารถโหลดรูปภาพได้'),
          ),
        ),
      );
    }

    if (_isPdf(widget.fileType)) {
      if (_pdfLoadFailed) {
        return _buildErrorState('ไม่สามารถโหลด PDF ได้');
      }
      if (_isPdfLoading || _localPdfPath == null) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.white),
        );
      }
      return PDFView(
        filePath: _localPdfPath!,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        pageSnap: true,
        defaultPage: 0,
        fitPolicy: FitPolicy.BOTH,
        onRender: (pages) {
          setState(() => _totalPages = pages ?? 0);
        },
        onPageChanged: (page, total) {
          setState(() {
            _currentPage = page ?? 0;
            _totalPages = total ?? 0;
          });
        },
        onError: (error) {
          debugPrint('PDF error: $error');
        },
      );
    }

    return _buildUnsupportedFileType();
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.white.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedFileType() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_drive_file,
            size: 64,
            color: AppColors.white.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่รองรับการดูไฟล์ประเภทนี้',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'กรุณาดาวน์โหลดเพื่อเปิดดู',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
