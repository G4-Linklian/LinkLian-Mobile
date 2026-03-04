import 'dart:io';
import 'package:LinkLian/core/utils/logger.dart';
import 'package:LinkLian/data/repository/community_bookmark_repository.dart';
import 'package:LinkLian/features/community/controllers/community_comment_controller.dart';
import 'package:LinkLian/features/community/controllers/community_detail_controller.dart';
import 'package:LinkLian/features/profile/controllers/bookmark_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/linklian-icon.dart';
import '../../../config/app_routes.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../data/model/community_post_model.dart';
import '../../../data/model/community_attachment_model.dart';
import '../../../data/repository/community_post_repository.dart';
import '../../auth/controller/auth_controller.dart';

class CardPostCommunity extends StatefulWidget {
  final CommunityPostModel post;
  final String? highlightKeyword;
  final bool showMoreButton;

  const CardPostCommunity({
    super.key,
    required this.post,
    this.highlightKeyword,
    this.showMoreButton = true,
  });

  @override
  State<CardPostCommunity> createState() => _CardPostCommunityState();
}

class _CardPostCommunityState extends State<CardPostCommunity> {
  int _currentAttachmentIndex = 0;
  String? _localPdfPath;
  bool _isPdfLoading = false;
  bool _pdfLoadFailed = false;
  bool _isExpanded = false;
  bool _isBookmarked = false;
  bool _isBookmarkLoading = false;

  final _bookmarkRepo = CommunityBookmarkRepository();

  bool _isLink(String type) {
    final t = type.toLowerCase();
    return t == 'link' || t.contains('link');
  }

  bool _isImage(String type) {
    final t = type.toLowerCase();
    return t == 'jpg' ||
        t == 'jpeg' ||
        t == 'png' ||
        t == 'webp' ||
        t.contains('image');
  }

  bool _isPdf(String type) {
    final t = type.toLowerCase();
    return t == 'pdf' || t.contains('pdf');
  }

  @override
  void initState() {
    super.initState();
    AppLogger.info(
      "CARD DATA -> postId: ${widget.post.postId}, "
      "communityId: ${widget.post.communityId}",
    );

    _loadBookmarkStatus();
  }

  Future<void> _loadBookmarkStatus() async {
    try {
      final status = await _bookmarkRepo.checkBookmark(widget.post.postId);

      if (!mounted) return;

      setState(() {
        _isBookmarked = status;
      });
    } catch (e) {
      AppLogger.info("[community]Bookmark load error: $e");
    }
  }

  void _openComment() {
    Get.toNamed(
      AppRoutes.communityComment,
      arguments: {
        'postCommuId': widget.post.postId,
        'communityId': widget.post.communityId,
        'post': widget.post,
        'userSysId': Get.find<AuthController>().userId.value,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final isOwner = widget.post.userId == auth.userId.value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openComment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildProfileAvatar(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${widget.post.firstName} ${widget.post.lastName}",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: AppColors.black.withValues(alpha: 0.5),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDateTime(widget.post.createdAt),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.black.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // if (widget.showMoreButton) _buildMoreButton(context),
                      if (widget.showMoreButton && isOwner)
                        _buildMoreButton(context),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildContentWithExpand(),

                  const SizedBox(height: 12),
                ],
              ),
            ),

            if (widget.post.attachments.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildAttachmentsPreview(),
              ),
            ],

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      onPressed: _openComment,
                      icon: LinkLianHugeIcon.comment(
                        size: 24,
                        color: AppColors.primaryPalette[700]!,
                        stroke: 2,
                      ),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                    ),
                  ),
                  const Spacer(),

                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      onPressed: _isBookmarkLoading ? null : _toggleBookmark,
                      icon: Icon(
                        _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: _isBookmarked
                            ? AppColors.primaryPalette[600]
                            : AppColors.primaryPalette[600],
                        size: 24,
                      ),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentWithExpand() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== CONTENT TEXT WITH CLICKABLE LINKS =====
        _buildRichTextContent(),

        if (widget.post.content.length > 150 && !_isExpanded)
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = true;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '...เพิ่มเติม',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryPalette[600],
                ),
              ),
            ),
          ),

        if (widget.post.content.length > 150 && _isExpanded)
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = false;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'ซ่อน',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryPalette[600],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRichTextContent() {
    final content = widget.post.content;
    final maxLines = _isExpanded ? null : 4;

    // URL regex pattern
    final urlPattern = RegExp(
      r'(https?://[^\s<>\[\]{}|\\^]+)',
      caseSensitive: false,
    );

    // Split content by URLs
    final matches = urlPattern.allMatches(content).toList();

    if (matches.isEmpty) {
      // No URLs, show plain text
      return Text(
        content,
        style: TextStyle(
          fontSize: 15,
          color: AppColors.black.withValues(alpha: 0.8),
        ),
        maxLines: maxLines,
        overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
      );
    }

    // Build rich text with clickable links
    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      // Add text before the URL
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: content.substring(lastEnd, match.start),
            style: TextStyle(
              fontSize: 15,
              color: AppColors.black.withValues(alpha: 0.8),
            ),
          ),
        );
      }

      // Add clickable URL
      final url = match.group(0)!;
      spans.add(
        TextSpan(
          text: url,
          style: TextStyle(
            fontSize: 15,
            color: AppColors.primaryPalette[600],
            decoration: TextDecoration.underline,
            decorationColor: AppColors.primaryPalette[600],
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              try {
                final uri = Uri.parse(url);
                final launched = await launchUrl(
                  uri,
                  mode: LaunchMode.platformDefault,
                );
                if (!launched) {
                  DialogHelper.showNotification(
                    title: 'ไม่สามารถเปิดลิงก์ได้',
                    message: url,
                    type: NotificationType.error,
                  );
                }
              } catch (e) {
                DialogHelper.showNotification(
                  title: 'ไม่สามารถเปิดลิงก์ได้',
                  message: 'กรุณาลองใหม่อีกครั้ง',
                  type: NotificationType.error,
                );
              }
            },
        ),
      );

      lastEnd = match.end;
    }

    // Add remaining text after last URL
    if (lastEnd < content.length) {
      spans.add(
        TextSpan(
          text: content.substring(lastEnd),
          style: TextStyle(
            fontSize: 15,
            color: AppColors.black.withValues(alpha: 0.8),
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
    );
  }

  // ================= ATTACHMENTS PREVIEW =================
  Widget _buildAttachmentsPreview() {
    final attachments = widget.post.attachments;
    final hasMultiple = attachments.length > 1;
    final currentFile = attachments[_currentAttachmentIndex];

    // Check if current file is a link
    final isLink = _isLink(currentFile.fileType);

    // For links, show link preview widget
    if (isLink) {
      return _buildLinkPreview(currentFile, hasMultiple, attachments.length);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.primaryPalette[50],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border.all(color: AppColors.primaryPalette[200]!),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Stack(
              children: [
                _buildFilePreview(currentFile),

                if (hasMultiple && _currentAttachmentIndex > 0)
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: _arrowButton(
                          Icons.chevron_left,
                          () => setState(() => _currentAttachmentIndex--),
                        ),
                      ),
                    ),
                  ),

                if (hasMultiple &&
                    _currentAttachmentIndex < attachments.length - 1)
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: _arrowButton(
                          Icons.chevron_right,
                          () => setState(() {
                            _currentAttachmentIndex++;
                            _localPdfPath = null;
                            _pdfLoadFailed = false;
                          }),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4E6),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            border: Border.all(color: AppColors.primaryPalette[200]!),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => _downloadFile(currentFile),
                icon: const Icon(Icons.download),
                color: AppColors.primaryPalette[700],
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  currentFile.originalName ?? _getFileName(currentFile.fileUrl),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.black.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _openFileFullscreen(currentFile),
                icon: const Icon(Icons.open_in_full),
                color: AppColors.primaryPalette[700],
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build link preview with metadata fetch
  Widget _buildLinkPreview(
    CommunityAttachmentModel file,
    bool hasMultiple,
    int totalCount,
  ) {
    return _LinkPreviewCard(
      url: file.fileUrl,
      hasMultiple: hasMultiple,
      currentIndex: _currentAttachmentIndex,
      totalCount: totalCount,
      onPrevious: _currentAttachmentIndex > 0
          ? () => setState(() => _currentAttachmentIndex--)
          : null,
      onNext: _currentAttachmentIndex < totalCount - 1
          ? () => setState(() {
              _currentAttachmentIndex++;
              _localPdfPath = null;
              _pdfLoadFailed = false;
            })
          : null,
    );
  }

  Widget _arrowButton(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      color: AppColors.white,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildFilePreview(CommunityAttachmentModel file) {
    if (_isImage(file.fileType)) {
      return Image.network(
        file.fileUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, _, _) {
          return _buildFileIcon(file.fileType);
        },
      );
    }

    if (_isPdf(file.fileType)) {
      return _buildPdfPreview(file.fileUrl);
    }

    return _buildFileIcon(file.fileType);
  }

  Widget _buildPdfPreview(String url) {
    // Don't retry if already failed
    if (_pdfLoadFailed) {
      return _buildPdfErrorState();
    }

    if (_localPdfPath == null && !_isPdfLoading) {
      _loadPdf(url);
    }

    if (_isPdfLoading || _localPdfPath == null) {
      return Container(
        color: Colors.grey.shade100,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      color: Colors.white,
      child: PDFView(
        filePath: _localPdfPath!,
        enableSwipe: false,
        swipeHorizontal: false,
        autoSpacing: false,
        pageFling: false,
        pageSnap: false,
        defaultPage: 0,
        fitPolicy: FitPolicy.BOTH,
        onRender: (pages) {
          AppLogger.info('[community]PDF rendered: $pages pages');
        },
        onError: (error) {
          AppLogger.info('[community]PDF error: $error');
        },
        onPageError: (page, error) {
          AppLogger.info('[community]PDF page error: $page | $error');
        },
      ),
    );
  }

  Widget _buildPdfErrorState() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf,
              size: 48,
              color: AppColors.primaryPalette[400],
            ),
            const SizedBox(height: 8),
            Text(
              'ไม่สามารถโหลด PDF ได้',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
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
      AppLogger.info('[community]PDF download error: $e');
      if (mounted) {
        setState(() {
          _isPdfLoading = false;
          _pdfLoadFailed = true;
        });
      }
    }
  }

  Widget _buildFileIcon(String fileType) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryPalette[50],
      child: Center(
        child: Icon(
          _getFileIconData(fileType),
          size: 80,
          color: AppColors.primaryPalette[400],
        ),
      ),
    );
  }

  IconData _getFileIconData(String fileType) {
    final type = fileType.toLowerCase();

    if (type.contains('pdf')) {
      return Icons.picture_as_pdf;
    }

    if (type.contains('image')) {
      return Icons.image;
    }

    if (type.contains('video')) {
      return Icons.video_file;
    }

    if (type.contains('word') || type.contains('doc')) {
      return Icons.description;
    }

    if (type.contains('excel') || type.contains('xls')) {
      return Icons.table_chart;
    }

    if (type.contains('powerpoint') || type.contains('ppt')) {
      return Icons.slideshow;
    }

    return Icons.insert_drive_file;
  }

  String _getFileName(String url) {
    return url.split('/').last.split('?').first;
  }

  // ================= MORE BUTTON =================
  Widget _buildMoreButton(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        _showPostMenu(context, details.globalPosition);
      },
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(Icons.more_horiz, size: 22),
      ),
    );
  }

  void _showPostMenu(BuildContext context, Offset position) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final auth = Get.find<AuthController>();
    final isOwner = widget.post.userId == auth.userId.value;

    final items = <PopupMenuEntry>[];

    if (isOwner) {
      items.add(
        PopupMenuItem(
          onTap: _onEditPost,
          child: const ListTile(
            leading: Icon(Icons.edit),
            title: Text('แก้ไขโพสต์'),
          ),
        ),
      );

      items.add(
        PopupMenuItem(
          onTap: _onDeletePost,
          child: ListTile(
            leading: Icon(Icons.delete, color: AppColors.dangerPalette[500]),
            title: Text(
              'ลบโพสต์',
              style: TextStyle(color: AppColors.dangerPalette[700]),
            ),
          ),
        ),
      );
    }

    if (items.isEmpty) return;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & overlay.size,
      ),
      items: items,
    );
  }

  void _onEditPost() async {
    final result = await Get.toNamed(
      AppRoutes.createPostCommunity,
      arguments: {
        'isEdit': true,
        'post': widget.post,
        'community_id': widget.post.communityId,
      },
    );

    if (result is CommunityPostModel) {
      if (Get.isRegistered<CommunityDetailController>()) {
        Get.find<CommunityDetailController>().updatePostInList(result);
      }

      if (Get.isRegistered<CommunityCommentController>()) {
        Get.find<CommunityCommentController>().post.value = result;
      }

      DialogHelper.showNotification(
        title: 'แก้ไขสำเร็จ',
        message: 'โพสต์ถูกอัปเดตแล้ว',
        type: NotificationType.success,
      );
    }
  }

  void _onDeletePost() async {
    AppLogger.info("[community]DELETE POST ID: ${widget.post.postId}");
    AppLogger.info(
      "[community]DELETE COMMUNITY ID: ${widget.post.communityId}",
    );
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณต้องการลบโพสต์นี้หรือไม่'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'ลบ',
              style: TextStyle(color: AppColors.dangerPalette[500]),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await CommunityPostRepository().deletePost(postId: widget.post.postId);
      if (Get.isRegistered<CommunityDetailController>()) {
        final controller = Get.find<CommunityDetailController>();
        controller.removePost(widget.post.postId);
      }
      if (Get.currentRoute == AppRoutes.communityComment) {
        Get.back(result: true);
      }

      DialogHelper.showNotification(
        title: 'ลบโพสต์สำเร็จ',
        message: 'โพสต์ถูกลบเรียบร้อยแล้ว',
        type: NotificationType.success,
      );
    } catch (e) {
      DialogHelper.showNotification(
        title: 'เกิดข้อผิดพลาด',
        message: 'ไม่สามารถลบโพสต์ได้: $e',
        type: NotificationType.error,
      );
    }
  }

  // void _onReportPost() {
  //   // TODO: Implement report post
  //   debugPrint('📝 Report post: ${widget.post.postId}');
  //   Get.snackbar(
  //     'รายงานโพสต์',
  //     'ฟีเจอร์นี้กำลังพัฒนา',
  //     snackPosition: SnackPosition.BOTTOM,
  //   );
  // }

  // ================= PROFILE AVATAR =================
  Widget _buildProfileAvatar() {
    if (widget.post.profilePic != null && widget.post.profilePic!.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(widget.post.profilePic!),
        backgroundColor: AppColors.primaryPalette[100],
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primaryPalette[200],
      child: Text(
        _getInitial("${widget.post.firstName} ${widget.post.lastName}"),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryPalette[700],
        ),
      ),
    );
  }

  String _getInitial(String? name) {
    if (name == null || name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  String _formatDateTime(DateTime dt) {
    final formatter = DateFormat('HH:mm • dd/MM/yyyy', 'th');
    return formatter.format(dt);
  }

  void _toggleBookmark() async {
    if (_isBookmarkLoading) return;

    setState(() => _isBookmarkLoading = true);

    try {
      final result = await _bookmarkRepo.toggleBookmark(
        postId: widget.post.postId,
      );

      if (!mounted) return;

      final action = result['action'];

      setState(() {
        _isBookmarked = action == 'created';
      });
      if (Get.isRegistered<BookmarkController>()) {
        Get.find<BookmarkController>().loadCommunityBookmarks();
      }

      DialogHelper.showNotification(
        title: 'สำเร็จ',
        message: action == 'created'
            ? 'บันทึกโพสต์เรียบร้อยแล้ว'
            : 'ลบบุ๊กมาร์กเรียบร้อยแล้ว',
        type: NotificationType.success,
      );
    } catch (e) {
      DialogHelper.showErrorDialog(description: "ไม่สามารถบันทึกได้");
    } finally {
      if (mounted) {
        setState(() => _isBookmarkLoading = false);
      }
    }
  }

  void _openFileFullscreen(CommunityAttachmentModel file) {
    Get.to(
      () => _FileViewerPage(file: file),
      transition: Transition.fadeIn,
      fullscreenDialog: true,
    );
  }

  Future<void> _downloadFile(CommunityAttachmentModel file) async {
    try {
      // Show loading dialog
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Get file name
      final fileName = file.originalName ?? _getFileName(file.fileUrl);

      // Download file
      final response = await http.get(Uri.parse(file.fileUrl));

      if (response.statusCode != 200) {
        throw Exception('ดาวน์โหลดล้มเหลว: HTTP ${response.statusCode}');
      }

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';

      // Write file to temporary directory
      final downloadedFile = File(filePath);
      await downloadedFile.writeAsBytes(response.bodyBytes);

      // Close loading
      Get.back();

      if (Platform.isIOS) {
        // iOS: Use Share Sheet to let user save file
        try {
          final result = await Share.shareXFiles([XFile(filePath)]);

          if (result.status == ShareResultStatus.success) {
            DialogHelper.showNotification(
              title: 'แชร์ไฟล์สำเร็จ',
              message: 'คุณสามารถบันทึกไฟล์ได้แล้ว',
              type: NotificationType.success,
            );
          }
        } catch (e) {
          // Fallback: Show file location
          DialogHelper.showNotification(
            title: 'ดาวน์โหลดสำเร็จ',
            message: 'ไฟล์ถูกบันทึกไว้แล้ว',
            type: NotificationType.success,
          );
        }
      } else {
        // Android: Save to Downloads folder with permission
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            DialogHelper.showNotification(
              title: 'ไม่มีสิทธิ์เข้าถึง',
              message: 'กรุณาอนุญาตการเข้าถึงที่เก็บข้อมูล',
              type: NotificationType.error,
            );
            return;
          }
        }

        // Copy to Downloads folder
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        String finalPath = '${downloadsDir.path}/$fileName';
        int counter = 1;
        while (await File(finalPath).exists()) {
          final nameParts = fileName.split('.');
          final extension = nameParts.length > 1 ? nameParts.last : '';
          final nameWithoutExt = nameParts.length > 1
              ? nameParts.sublist(0, nameParts.length - 1).join('.')
              : fileName;
          finalPath =
              '${downloadsDir.path}/$nameWithoutExt ($counter)${extension.isNotEmpty ? '.$extension' : ''}';
          counter++;
        }

        await downloadedFile.copy(finalPath);

        DialogHelper.showNotification(
          title: 'ดาวน์โหลดสำเร็จ',
          message: 'บันทึกไฟล์ไว้ที่ Download',
          type: NotificationType.success,
        );
      }
    } catch (e) {
      // Close loading if still open
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      DialogHelper.showNotification(
        title: 'เกิดข้อผิดพลาด',
        message: 'ไม่สามารถดาวน์โหลดไฟล์ได้',
        type: NotificationType.error,
      );
    }
  }
}

// ================= FULLSCREEN FILE VIEWER =================
class _FileViewerPage extends StatefulWidget {
  final CommunityAttachmentModel file;

  const _FileViewerPage({required this.file});

  @override
  State<_FileViewerPage> createState() => _FileViewerPageState();
}

class _FileViewerPageState extends State<_FileViewerPage> {
  String? _localPdfPath;
  bool _isPdfLoading = false;
  bool _pdfLoadFailed = false;
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    if (_isPdf(widget.file.fileType)) {
      _loadPdf(widget.file.fileUrl);
    }
  }

  bool _isImage(String type) {
    final t = type.toLowerCase();
    return t == 'jpg' ||
        t == 'jpeg' ||
        t == 'png' ||
        t == 'webp' ||
        t.contains('image');
  }

  bool _isPdf(String type) {
    final t = type.toLowerCase();
    return t == 'pdf' || t.contains('pdf');
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
      if (mounted) {
        setState(() {
          _isPdfLoading = false;
          _pdfLoadFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryPalette[200],
      appBar: AppBar(
        backgroundColor: AppColors.primaryPalette[500]!.withValues(alpha: 0.8),
        leading: IconButton(
          icon: Icon(LinkLianIcon.close, color: AppColors.dangerPalette[700]),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.file.originalName ?? 'ไฟล์แนบ',
          style: TextStyle(color: AppColors.primaryPalette[900], fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_isPdf(widget.file.fileType) && _totalPages > 0)
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
      body: _buildFileContent(),
    );
  }

  Widget _buildFileContent() {
    if (_isImage(widget.file.fileType)) {
      return Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            widget.file.fileUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                _buildErrorState('ไม่สามารถโหลดรูปภาพได้'),
          ),
        ),
      );
    }

    if (_isPdf(widget.file.fileType)) {
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
          setState(() {
            _totalPages = pages ?? 0;
          });
          AppLogger.info('[community]PDF rendered: $pages pages');
        },
        onPageChanged: (page, total) {
          setState(() {
            _currentPage = page ?? 0;
            _totalPages = total ?? 0;
          });
        },
        onError: (error) {
          AppLogger.info('[community]PDF error: $error');
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

// ================= LINK PREVIEW CARD =================
class _LinkPreviewCard extends StatefulWidget {
  final String url;
  final bool hasMultiple;
  final int currentIndex;
  final int totalCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _LinkPreviewCard({
    required this.url,
    this.hasMultiple = false,
    this.currentIndex = 0,
    this.totalCount = 1,
    this.onPrevious,
    this.onNext,
  });

  @override
  State<_LinkPreviewCard> createState() => _LinkPreviewCardState();
}

class _LinkPreviewCardState extends State<_LinkPreviewCard> {
  Metadata? _metadata;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchMetadata();
  }

  @override
  void didUpdateWidget(covariant _LinkPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _fetchMetadata();
    }
  }

  Future<void> _fetchMetadata() async {
    setState(() => _loading = true);

    try {
      final data = await MetadataFetch.extract(widget.url);
      if (mounted) {
        setState(() {
          _metadata = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openLink() async {
    final url = widget.url;

    try {
      final uri = Uri.parse(url);

      // Try multiple launch modes
      bool launched = false;

      // Try 1: Platform default
      try {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (launched) {
          return;
        }
      } catch (e) {
        AppLogger.info('[community]platformDefault failed: $e');
      }

      // Try 2: External application
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (launched) {
            return;
          }
        } catch (e) {
          AppLogger.info('[community]externalApplication failed: $e');
        }
      }

      // Try 3: In-app browser (last resort)
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
          if (launched) {
            return;
          }
        } catch (e) {
          AppLogger.info('[community]inAppBrowserView failed: $e');
        }
      }

      if (!launched) {
        DialogHelper.showNotification(
          title: 'ไม่สามารถเปิดลิงก์ได้',
          message: url,
          type: NotificationType.error,
        );
      }
    } catch (e) {
      DialogHelper.showNotification(
        title: 'ไม่สามารถเปิดลิงก์ได้',
        message: 'กรุณาลองใหม่อีกครั้ง',
        type: NotificationType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openLink,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Link Preview Container with Border
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryPalette[200]!),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPalette[100]!.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Preview Image
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPalette[50],
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(8),
                    ),
                  ),
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        )
                      : _metadata?.image != null && _metadata!.image!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(8),
                          ),
                          child: Image.network(
                            _metadata!.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildLinkIcon(),
                          ),
                        )
                      : _buildLinkIcon(),
                ),

                // Title & URL
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.link,
                              size: 13,
                              color: AppColors.primaryPalette[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _metadata?.title ?? 'ลิงก์',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  color: AppColors.primaryPalette[800],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.url,
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.primaryPalette[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                // Open icon
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.open_in_new,
                    size: 13,
                    color: AppColors.primaryPalette[400],
                  ),
                ),
              ],
            ),
          ),

          // Navigation and Counter
          if (widget.hasMultiple)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: widget.onPrevious != null
                        ? IconButton(
                            onPressed: widget.onPrevious,
                            icon: const Icon(Icons.chevron_left, size: 18),
                            color: AppColors.primaryPalette[600],
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(width: 8),

                  // Counter
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPalette[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryPalette[200]!),
                    ),
                    child: Text(
                      '${widget.currentIndex + 1}/${widget.totalCount}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryPalette[600],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  SizedBox(
                    width: 28,
                    height: 28,
                    child: widget.onNext != null
                        ? IconButton(
                            onPressed: widget.onNext,
                            icon: const Icon(Icons.chevron_right, size: 18),
                            color: AppColors.primaryPalette[600],
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLinkIcon() {
    return Center(
      child: Icon(Icons.link, size: 32, color: AppColors.primaryPalette[300]),
    );
  }
}
