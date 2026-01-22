import 'package:LinkLian/core/constants/linklian-icon.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../../data/model/post_model.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/sizes.dart';
import 'package:intl/intl.dart';
import '../../classes/controllers/class_detail_controller.dart';
import '../../../config/app_routes.dart';
import '../../classes/controllers/create_post_controller.dart';
import '../../auth/controller/auth_controller.dart';
import '../../../core/utils/post_permission.dart';
import '../../../data/repository/post_repository.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../profile/controllers/bookmark_controller.dart';

class CardPost extends StatefulWidget {
  final PostModel post;
  final Function(int postId)? onSelectForAI;
  const CardPost({super.key, required this.post, this.onSelectForAI});

  @override
  State<CardPost> createState() => _CardPostState();
}

class _CardPostState extends State<CardPost> {
  int _currentAttachmentIndex = 0;
  String? _localPdfPath;
  bool _isPdfLoading = false;
  bool _isExpanded = false;
  late final BookmarkController bookmarkController;
  late final PostPermission permission;
  late final ClassDetailController classController;

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
    permission = PostPermission(post: widget.post, auth: auth);
    bookmarkController = Get.find<BookmarkController>();
    classController = Get.find<ClassDetailController>();
  }

  bool get _isCurrentUserTeacher {
    final auth = Get.find<AuthController>();
    final role = auth.roleName.value?.toLowerCase() ?? '';
    return role == 'teacher' || role == 'instructor';
  }

  bool get _isTeacherPost {
    final roleName = widget.post.roleName?.toLowerCase() ?? '';
    return roleName == 'teacher' || roleName == 'instructor';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
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
                    _buildPostTypeTag(),
                    const Spacer(),
                    if (permission.canShowMore) _buildMoreButton(context),
                    if (permission.canSelectAI) ...[
                      const SizedBox(width: 8),
                      _buildRadio(),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // ===== PROFILE ROW =====
                Row(
                  children: [
                    _buildProfileAvatar(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.displayName ?? 'ไม่ทราบชื่อ',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!widget.post.isAnonymous &&
                              widget.post.roleName != null)
                            Text(
                              _getRoleLabel(widget.post.roleName!),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.black.withOpacity(0.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // TITLE - แสดงเฉพาะครู
                if (_isTeacherPost) ...[
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
                        color: AppColors.black.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _formatDateTime(widget.post.createdAt),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.black.withOpacity(0.5),
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
                    onPressed: () {
                      Get.toNamed(
                        AppRoutes.comment,
                        arguments: {
                          'postId': widget.post.postId,
                          'postContentId': widget.post.postContentId,
                          'post': widget.post,
                        },
                      );
                    },
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
                if (!_isCurrentUserTeacher)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Obx(() {
                      // ตรวจสอบ bookmark status
                      final isBookmarked = bookmarkController.isBookmarked(
                        widget.post.postId,
                      );

                      return IconButton(
                        onPressed: () async {
                          // เรียก toggle bookmark
                          await bookmarkController.toggleBookmark(
                            postId: widget.post.postId,
                            postContentId: widget.post.postContentId,
                          );
                        },
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
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
    );
  }

  //  Content with Expand Button
  Widget _buildContentWithExpand() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== CONTENT TEXT =====
        Text(
          widget.post.content,
          style: TextStyle(
            fontSize: 15,
            color: AppColors.black.withOpacity(0.8),
          ),
          maxLines: _isExpanded ? null : 4,
          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),

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
        color = AppColors.primaryPalette[500]!;
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
        color: color.withOpacity(0.15),
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

  Widget _buildRadio() {
    return Obx(() {
      final controller = Get.find<ClassDetailController>();
      final isSelected = controller.selectedPostIdsForAI.contains(
        widget.post.postId,
      );

      return InkWell(
        onTap: widget.onSelectForAI == null
            ? null
            : () => widget.onSelectForAI!(widget.post.postId),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryPalette[600]!
                  : Colors.grey.shade400,
              width: 2,
            ),
            color: isSelected
                ? AppColors.primaryPalette[600]
                : Colors.transparent,
          ),
          child: isSelected
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
      );
    });
  }

  // ===== ATTACHMENTS PREVIEW =====
  Widget _buildAttachmentsPreview() {
    final attachments = widget.post.attachments!;
    final hasMultiple = attachments.length > 1;
    final currentFile = attachments[_currentAttachmentIndex];

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
                onPressed: () {},
                icon: const Icon(Icons.download),
                color: AppColors.primaryPalette[700],
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getFileName(currentFile.fileUrl),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.black.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
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

    if (permission.canEdit) {
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

    if (permission.canDelete) {
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

    if (permission.canReport) {
      items.add(
        PopupMenuItem(
          onTap: _onReportPost,
          child: const ListTile(
            leading: Icon(Icons.flag),
            title: Text('รายงานโพสต์'),
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

  void _onReportPost() {
    final postId = widget.post.postContentId;
  }

  Widget _arrowButton(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      color: AppColors.white,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withOpacity(0.5),
      ),
    );
  }

  Widget _buildFilePreview(PostAttachmentModel file) {
    if (_isImage(file.fileType)) {
      return Image.network(
        file.fileUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) {
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

  Future<void> _loadPdf(String url) async {
    setState(() {
      _isPdfLoading = true;
    });

    try {
      final fileName = url.split('/').last.split('?').first;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');

      if (!await file.exists()) {
        final response = await http.get(Uri.parse(url));
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
      setState(() {
        _isPdfLoading = false;
      });
    }
  }

  void _onEditPost() async {
    final result = await Get.toNamed(
      AppRoutes.createPost,
      arguments: {
        'mode': CreatePostMode.edit,
        'post': widget.post,
        'source': CreatePostSource.classDetail,
        'sectionId': classController.sectionId.value,
      },
    );

    if (result?['success'] == true && result?['edited'] == true) {
      await classController.fetchPosts(keepScroll: true);
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
      await PostRepository().deletePost(
        postId: postId,
        postContentId: postContentId,
      );

      await classController.fetchPosts();

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
    if (type.contains('excel') || type.contains('xls'))
      return Icons.table_chart;
    if (type.contains('powerpoint') || type.contains('ppt'))
      return Icons.slideshow;
    return Icons.insert_drive_file;
  }

  String _getFileName(String url) {
    return url.split('/').last.split('?').first;
  }

  Widget _buildProfileAvatar() {
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
}
