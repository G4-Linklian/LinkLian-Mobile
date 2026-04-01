import 'package:LinkLian/core/constants/linklian-icon.dart';
import 'package:LinkLian/core/services/api_client.dart';
import 'package:LinkLian/core/utils/logger.dart';
import 'package:LinkLian/core/utils/profile_popup_helper.dart';
import 'package:LinkLian/features/shared/repositories/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import '../../../shared/models/post_model.dart';
import '../../../../core/constants/colors.dart';
import 'package:intl/intl.dart';
import '../controllers/class_detail_controller.dart';
import '../../../../config/app_routes.dart';
import '../controllers/create_post_controller.dart';
import '../../../auth/controller/auth_controller.dart';
import '../../../../core/utils/post_permission.dart';
import '../../../shared/repositories/post_repository.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../../../shared/presentations/bookmark_controller.dart';

class CardPost extends StatefulWidget {
  final PostModel post;
  final Function(int postId)? onSelectForAI;
  final ClassDetailController? classDetailController;
  final bool returnAfterDelete;

  const CardPost({
    super.key,
    required this.post,
    this.onSelectForAI,
    this.classDetailController,
    this.returnAfterDelete = false,
  });

  @override
  State<CardPost> createState() => _CardPostState();
}

class _CardPostState extends State<CardPost> {
  int _currentAttachmentIndex = 0;
  String? _localPdfPath;
  bool _isPdfLoading = false;
  bool _pdfLoadFailed = false;
  bool _isExpanded = false;
  BookmarkController? _bookmarkController;
  PostPermission? _permission;
  ClassDetailController? _classController;

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
    final auth = Get.find<AuthController>();
    _permission = PostPermission(post: widget.post, auth: auth);

    _classController = widget.classDetailController;

    if (_classController == null && Get.isRegistered<ClassDetailController>()) {
      _classController = Get.find<ClassDetailController>();
    }

    if (Get.isRegistered<BookmarkController>()) {
      _bookmarkController = Get.find<BookmarkController>();
    }
  }

  bool get _hasClassController => _classController != null;
  bool get _hasBookmarkController => _bookmarkController != null;

  bool get _isCurrentUserTeacher {
    final auth = Get.find<AuthController>();
    final role = auth.roleName.value?.toLowerCase() ?? '';
    return role == 'teacher' || role == 'instructor';
  }

  bool get _shouldShowTitle => widget.post.title.trim().isNotEmpty;

  bool get _canSelectForAI {
    final postType = widget.post.postType.toLowerCase();
    return postType == 'announcement';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openCommentPage,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, top: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.22),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== MAIN CONTENT WITH PADDING =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== TAG + ACTIONS =====
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildPostTypeTag(),
                            if (widget.post.postType.toLowerCase() ==
                                'assignment')
                              ..._buildAssignmentTags(),
                          ],
                        ),
                      ),
                      if (_permission?.canShowMore == true)
                        _buildMoreButton(context),
                      if (!_isCurrentUserTeacher &&
                          _hasClassController &&
                          _canSelectForAI) ...[
                        const SizedBox(width: 8),
                        _buildRadio(),
                      ],
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ===== PROFILE ROW =====
                  // Row(
                  //   children: [
                  //     _buildProfileAvatar(),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          final auth = Get.find<AuthController>();

                          if (widget.post.userSysId == auth.userId.value) {
                            return;
                          }

                          _openProfilePopup();
                        },
                        child: _buildProfileAvatar(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                final auth = Get.find<AuthController>();

                                if (widget.post.userSysId ==
                                    auth.userId.value) {
                                  return;
                                }

                                _openProfilePopup();
                              },
                              child: Text(
                                widget.post.isUserDeleted
                                    ? 'ไม่มีบัญชีผู้ใช้งาน'
                                    : widget.post.displayName ?? 'ไม่ทราบชื่อ',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (!widget.post.isAnonymous &&
                                widget.post.roleName != null)
                              Text(
                                _getRoleLabel(widget.post.roleName!),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.black.withValues(alpha: 0.5),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // TITLE - show whenever post_content has a title,
                  // even if the posting user has been deleted.
                  if (_shouldShowTitle) ...[
                    Text(
                      widget.post.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // ===== CONTENT WITH EXPAND BUTTON =====
                  _buildContentWithExpand(),

                  const SizedBox(height: 12),

                  // ===== TIME + DATE =====
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.black.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _formatDateTime(widget.post.createdAt),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.black.withValues(alpha: 0.5),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ===== ATTACHMENTS =====
            if (widget.post.attachments != null &&
                widget.post.attachments!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildAttachmentsPreview(),
              ),
            ],

            // ===== BOTTOM ROW: COMMENT ICON + BOOKMARK =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      onPressed: _openCommentPage,
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

                  // BOOKMARK BUTTON - แสดงเฉพาะนักเรียน (ไม่แสดงสำหรับครู)
                  if (!_isCurrentUserTeacher && _hasBookmarkController)
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Obx(() {
                        // ตรวจสอบ bookmark status
                        final isBookmarked = _bookmarkController!.isBookmarked(
                          widget.post.postId,
                        );

                        return IconButton(
                          onPressed: () async {
                            // เรียก toggle bookmark
                            await _bookmarkController!.toggleBookmark(
                              postId: widget.post.postId,
                              postContentId: widget.post.postContentId,
                            );
                          },
                          icon: Icon(
                            isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: isBookmarked
                                ? AppColors.primaryPalette[600]
                                : AppColors.primaryPalette[600],
                            size: 24,
                          ),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          splashRadius: 20,
                        );
                      }),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //  Content with Expand Button
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

        // ===== COLLAPSE BUTTON =====
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

  /// Build rich text content with clickable links
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
              appLog.info('[Card Post widget] Tapped link in content: $url');
              try {
                final uri = Uri.parse(url);
                final launched = await launchUrl(
                  uri,
                  mode: LaunchMode.platformDefault,
                );
                if (!launched) {
                  Get.snackbar(
                    'ไม่สามารถเปิดลิงก์ได้',
                    url,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              } catch (e) {
                DialogHelper.showNotification(
                  title: 'ไม่สามารถเปิดลิงก์ได้',
                  message: 'เกิดข้อผิดพลาดขณะพยายามเปิดลิงก์นี้',
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

  // ===== POST TYPE TAG =====
  Widget _buildPostTypeTag() {
    Color color;
    String label;

    switch (widget.post.postType.toLowerCase()) {
      case 'announcement':
        color = AppColors.buttonPalette[700]!;
        label = 'ประกาศ';
        break;
      case 'assignment':
        color = AppColors.primaryPalette[600]!;
        label = 'การบ้าน';
        break;
      case 'question':
        color = AppColors.successPalette[700]!;
        label = 'คำถาม';
        break;
      default:
        color = AppColors.gray;
        label = widget.post.postType;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // ===== ASSIGNMENT TAGS (กำหนดส่ง + คะแนน) =====
  List<Widget> _buildAssignmentTags() {
    final color = AppColors.primaryPalette[600]!;

    // Format due date
    String dueDateText = 'ไม่ระบุ';
    if (widget.post.dueDate != null) {
      try {
        final formatter = DateFormat('dd/MM/yy HH:mm', 'th');
        dueDateText = formatter.format(widget.post.dueDate!);
      } catch (e) {
        dueDateText = 'ไม่ระบุ';
      }
    }

    // Get max score - default to 0 if null
    final maxScore = widget.post.maxScore;
    final scoreText = maxScore == null
        ? '0'
        : maxScore % 1 == 0
        ? maxScore.toInt().toString()
        : maxScore.toString();
    final assignmentTypeText = widget.post.isGroup == true
        ? 'งานกลุ่ม'
        : 'งานเดี่ยว';

    return [
      // Due Date Tag
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              dueDateText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),

      // Score Tag
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              '$scoreText คะแนน',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),

      // Assignment Type Tag
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          assignmentTypeText,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    ];
  }

  Widget _buildRadio() {
    return Obx(() {
      // ถ้าไม่มี classController ไม่แสดง AI button (เช่นอยู่ในหน้า search)
      if (!_hasClassController) {
        return const SizedBox.shrink();
      }

      final isSelected = _classController!.selectedPostIdsForAI.contains(
        widget.post.postContentId,
      );

      // Check if can select this post (either already selected or has room)
      final canSelect = _classController!.canSelectForAI(
        widget.post.postContentId,
      );

      return GestureDetector(
        onTap: () {
          if (canSelect && widget.onSelectForAI != null) {
            widget.onSelectForAI!(widget.post.postContentId);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryPalette[600]
                : canSelect
                ? AppColors.primaryPalette[100]
                : AppColors.gray.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryPalette[600]!
                  : canSelect
                  ? AppColors.primaryPalette[400]!
                  : AppColors.gray.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 14,
                color: isSelected
                    ? Colors.white
                    : canSelect
                    ? AppColors.primaryPalette[600]
                    : AppColors.gray,
              ),
              const SizedBox(width: 4),
              Text(
                'AI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : canSelect
                      ? AppColors.primaryPalette[600]
                      : AppColors.gray,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ===== ATTACHMENTS PREVIEW =====
  Widget _buildAttachmentsPreview() {
    final attachments = widget.post.attachments!;
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
                            _pdfLoadFailed =
                                false; // Reset on attachment change
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
    PostAttachmentModel file,
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

    final items = <PopupMenuEntry>[];

    if (_permission?.canEdit == true) {
      items.add(
        PopupMenuItem(
          onTap: _onEditPost,
          child: const ListTile(
            leading: Icon(Icons.edit),
            title: Text('แก้ไขโพสต์'),
          ),
        ),
      );
    }

    if (_permission?.canDelete == true) {
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

  Widget _buildFilePreview(PostAttachmentModel file) {
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
          debugPrint('PDF rendered: $pages pages');
        },
        onError: (error) {
          debugPrint('PDF error: $error');
        },
        onPageError: (page, error) {
          debugPrint('PDF page error: $page | $error');
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
      debugPrint('PDF download error: $e');
      if (mounted) {
        setState(() {
          _isPdfLoading = false;
          _pdfLoadFailed = true;
        });
      }
    }
  }

  void _onEditPost() async {
    if (!_hasClassController) {
      Get.snackbar(
        'ไม่สามารถแก้ไขได้',
        'กรุณากลับไปหน้าห้องเรียนเพื่อแก้ไขโพสต์',
      );
      return;
    }

    final result = await Get.toNamed(
      AppRoutes.createPost,
      arguments: {
        'mode': CreatePostMode.edit,
        'post': widget.post,
        'source': CreatePostSource.classDetail,
        'sectionId': _classController!.sectionId.value,
      },
    );

    if (result?['success'] == true && result?['edited'] == true) {
      debugPrint('📝 Refreshing posts after edit...');
      await _classController!.fetchPosts(keepScroll: true);
      DialogHelper.showNotification(
        title: 'แก้ไขโพสต์สำเร็จ',
        message: 'โพสต์ของคุณถูกอัปเดตแล้ว',
        type: NotificationType.success,
      );
    }
  }

  void _onDeletePost() async {
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

    final postId = widget.post.postId;
    final postContentId = widget.post.postContentId;
    try {
      // ส่งทั้ง postId และ postContentId
      await PostRepository().deletePost(
        postId: postId,
        postContentId: postContentId,
      );

      if (widget.returnAfterDelete) {
        Get.back(result: {'deleted': true, 'deletedPostId': postId});
      } else if (_hasClassController) {
        _classController!.removePostOptimistic(postId);
        await _classController!.fetchPosts(keepScroll: true);
      } else {
        // When deleting from CommentPage, return to ClassDetail with delete result.
        Get.back(result: {'deleted': true, 'deletedPostId': postId});
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

  Future<void> _openCommentPage() async {
    final result = await Get.toNamed(
      AppRoutes.comment,
      arguments: {
        'postId': widget.post.postId,
        'postContentId': widget.post.postContentId,
        'post': widget.post,
      },
    );

    if (!_hasClassController || result is! Map) return;

    final deleted = result['deleted'] == true;
    final deletedPostId = result['deletedPostId'];
    if (!deleted || deletedPostId == null) return;

    final parsedDeletedPostId = deletedPostId is int
        ? deletedPostId
        : int.tryParse(deletedPostId.toString());
    if (parsedDeletedPostId == null) return;

    _classController!.removePostOptimistic(parsedDeletedPostId);
    await _classController!.fetchPosts(keepScroll: true);
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

  Future<void> _openProfilePopup() async {
    if (widget.post.isAnonymous) return;
    if (widget.post.userSysId == null) return;

    final auth = Get.find<AuthController>();

    if (auth.userId.value == widget.post.userSysId) {
      return;
    }

    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final repo = ProfileRepository(ApiClient());

      // final profile = await repo.getProfile(widget.post.userSysId!);

      // Get.back();

      // showProfilePopup(profile);
      final profile = await repo.getProfile(widget.post.userSysId!);

      Get.back();

      final isDeletedUser = profile.fullName.isEmpty;

      if (isDeletedUser) {
        DialogHelper.showNotification(
          title: 'ไม่มีบัญชีผู้ใช้งาน',
          message: 'บัญชีนี้ถูกลบแล้ว',
          type: NotificationType.warning,
        );
        return;
      }

      showProfilePopup(profile);
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();

      Get.snackbar('เกิดข้อผิดพลาด', 'ไม่สามารถโหลดข้อมูลโปรไฟล์ได้');
    }
  }

  String _formatDateTime(DateTime dt) {
    final formatter = DateFormat('HH:mm • dd/MM/yyyy', 'th');
    return formatter.format(dt);
  }

  IconData _getFileIconData(String fileType) {
    final type = fileType.toLowerCase();
    if (type.contains('pdf')) return Icons.picture_as_pdf;
    if (type.contains('image')) return Icons.image;
    if (type.contains('video')) return Icons.video_file;
    if (type.contains('word') || type.contains('doc')) return Icons.description;
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

  Widget _buildProfileAvatar() {
    if (widget.post.isUserDeleted) {
      return Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Color(0xFFE5E7EB),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          LinkLianIcon.userOff,
          size: 26,
          color: Color(0xFF9CA3AF),
        ),
      );
    }

    if (widget.post.isAnonymous) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primaryPalette[100],
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person,
          size: 28,
          color: AppColors.primaryPalette[600],
        ),
      );
    }

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
        _getInitial(widget.post.displayName),
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

  String _getRoleLabel(String roleName) {
    switch (roleName.toLowerCase()) {
      case 'teacher':
        return 'ครู';
      case 'instructor':
        return 'อาจารย์';
      case 'high school student':
        return 'นักเรียน';
      case 'uni student':
        return 'นักศึกษา';
      default:
        return roleName;
    }
  }

  /// Open file in fullscreen mode
  void _openFileFullscreen(PostAttachmentModel file) {
    Get.to(
      () => _FileViewerPage(file: file),
      transition: Transition.fadeIn,
      fullscreenDialog: true,
    );
  }

  /// Download file to device storage
  Future<void> _downloadFile(PostAttachmentModel file) async {
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
            Get.snackbar(
              'แชร์ไฟล์สำเร็จ',
              'คุณสามารถบันทึกไฟล์ได้แล้ว',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
              backgroundColor: AppColors.successPalette[100],
            );
          }
        } catch (e) {
          // Fallback: Show file location
          Get.snackbar(
            'ดาวน์โหลดสำเร็จ',
            'ไฟล์ถูกบันทึกไว้แล้ว\n$filePath',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
            backgroundColor: AppColors.successPalette[100],
          );
        }
      } else {
        // Android: Save to Downloads folder with permission
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            Get.snackbar(
              'ไม่มีสิทธิ์เข้าถึง',
              'กรุณาอนุญาตการเข้าถึงที่เก็บข้อมูลเพื่อดาวน์โหลดไฟล์',
              snackPosition: SnackPosition.BOTTOM,
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

        Get.snackbar(
          'ดาวน์โหลดสำเร็จ',
          'บันทึกไฟล์ไว้ที่: Download/$fileName',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
          backgroundColor: AppColors.successPalette[100],
        );
      }

      debugPrint('✅ File downloaded: $fileName');
    } catch (e) {
      // Close loading if still open
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      debugPrint('❌ Download error: $e');

      Get.snackbar(
        'เกิดข้อผิดพลาด',
        'ไม่สามารถดาวน์โหลดไฟล์ได้: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.dangerPalette[100],
      );
    }
  }
}

/// Fullscreen File Viewer Page
class _FileViewerPage extends StatefulWidget {
  final PostAttachmentModel file;

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
      debugPrint('PDF download error: $e');
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
          debugPrint('PDF rendered: $pages pages');
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

/// Link Preview Card Widget with metadata fetch (Compact version)
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
      debugPrint('❌ Metadata fetch error: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openLink() async {
    final url = widget.url;
    debugPrint('🔗 Opening link: $url');

    try {
      final uri = Uri.parse(url);

      // Try multiple launch modes
      bool launched = false;

      // Try 1: Platform default
      try {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (launched) {
          debugPrint('✅ Opened with platformDefault');
          return;
        }
      } catch (e) {
        debugPrint('⚠️ platformDefault failed: $e');
      }

      // Try 2: External application
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (launched) {
            debugPrint('✅ Opened with externalApplication');
            return;
          }
        } catch (e) {
          debugPrint('⚠️ externalApplication failed: $e');
        }
      }

      // Try 3: In-app browser (last resort)
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
          if (launched) {
            debugPrint('✅ Opened with inAppBrowserView');
            return;
          }
        } catch (e) {
          debugPrint('⚠️ inAppBrowserView failed: $e');
        }
      }

      if (!launched) {
        Get.snackbar(
          'ไม่สามารถเปิดลิงก์ได้',
          'ลิงก์: $url',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      debugPrint('❌ Error opening link: $e');
      Get.snackbar(
        'ไม่สามารถเปิดลิงก์ได้',
        'กรุณาลองใหม่อีกครั้ง',
        snackPosition: SnackPosition.BOTTOM,
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
                // Preview Image (Compact)
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

          // Navigation + Counter (Outside border, แสดงเฉพาะเมื่อมีหลายลิงก์)
          if (widget.hasMultiple)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Left Arrow
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: widget.onPrevious != null
                        ? IconButton(
                            onPressed: widget.onPrevious,
                            icon: Icon(Icons.chevron_left, size: 18),
                            color: AppColors.primaryPalette[600],
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        : SizedBox.shrink(),
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

                  // Right Arrow
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: widget.onNext != null
                        ? IconButton(
                            onPressed: widget.onNext,
                            icon: Icon(Icons.chevron_right, size: 18),
                            color: AppColors.primaryPalette[600],
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        : SizedBox.shrink(),
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
