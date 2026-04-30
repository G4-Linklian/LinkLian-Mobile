import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/linklian-icon.dart';
import '../../../../core/constants/sizes.dart';
import '../../data/models/student_submission_status_model.dart';
import '../../data/models/submission_detail_model.dart';
import '../controllers/teacher_submission_controller.dart';
import '../../data/repositories/assignment_repository.dart';
import '../../data/repositories/submission_repository.dart';

class StudentAssignmentDetailPage extends StatefulWidget {
  const StudentAssignmentDetailPage({super.key});

  @override
  State<StudentAssignmentDetailPage> createState() =>
      _StudentAssignmentDetailPageState();
}

class _StudentAssignmentDetailPageState
    extends State<StudentAssignmentDetailPage> {
  late TeacherSubmissionController _controller;
  final _controllerReady = false.obs;

  // For individual mode
  StudentSubmissionStatusModel? _student;
  // For group mode
  GroupSubmissionItem? _groupItem;

  bool _isGroup = false;
  double? _maxScore;
  String? _subjectName;

  // Submitted-only dropdown
  final _showDropdown = false.obs;
  final _dropdownSearch = ''.obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePage();
    });
  }

  Future<void> _initializePage() async {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _isGroup = args['isGroup'] == true;
    _maxScore = args['maxScore'] != null
        ? (args['maxScore'] as num).toDouble()
        : null;
    _subjectName = args['subjectName'] as String?;
    final assignmentId = args['assignmentId'] as int?;

    // Ensure controller exists
    if (!Get.isRegistered<TeacherSubmissionController>()) {
      Get.put<TeacherSubmissionController>(
        TeacherSubmissionController(
          repo: Get.find<AssignmentRepository>(),
          submissionRepo: Get.find<SubmissionRepository>(),
        ),
      );
    }
    _controller = Get.find<TeacherSubmissionController>();
    _controller.maxScore = _maxScore;
    if (_controller.assignmentId == null && assignmentId != null) {
      _controller.assignmentId = assignmentId;
    }

    if (assignmentId != null) {
      await _controller.fetchStudents();
    }

    if (_isGroup) {
      final initialGroup = args['groupItem'] as GroupSubmissionItem?;
      _groupItem = _findLatestGroup(initialGroup) ?? initialGroup;
      if (_groupItem != null) _controller.selectGroup(_groupItem!);
    } else {
      final initialStudent = args['student'] as StudentSubmissionStatusModel?;
      _student = _findLatestStudent(initialStudent) ?? initialStudent;
      if (_student != null) _controller.selectStudent(_student!);
    }

    if (!mounted) return;
    _controllerReady.value = true;
  }

  StudentSubmissionStatusModel? _findLatestStudent(
    StudentSubmissionStatusModel? current,
  ) {
    if (current == null) return null;
    if (current.userSysId == null) return current;
    for (final s in _controller.allStudents) {
      if (s.userSysId != null && s.userSysId == current.userSysId) return s;
    }
    return null;
  }

  GroupSubmissionItem? _findLatestGroup(GroupSubmissionItem? current) {
    if (current == null) return null;
    for (final g in _controller.groupedList) {
      if (g.groupId == current.groupId) return g;
    }
    return null;
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String get _pageTitle {
    if (_isGroup) return _groupItem?.groupName ?? 'กลุ่ม';
    return _student?.displayName ?? 'นักเรียน';
  }

  bool get _hasSubmitted {
    if (_isGroup) return _groupItem?.hasSubmitted ?? false;
    return _student?.hasSubmitted ?? false;
  }

  DateTime? get _submittedAt {
    if (_isGroup) return _groupItem?.submittedAt;
    return _student?.submittedAt;
  }

  DateTime? get _markedAt {
    if (_isGroup) return _groupItem?.markedAt;
    return _student?.markedAt;
  }

  String _formatDateTime(DateTime dt) =>
      DateFormat('dd/MM/yy HH:mm น.', 'th').format(dt);

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  IconData _fileIcon(String? fileType) {
    switch ((fileType ?? '').toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _openFilePreview(SubmissionAttachmentDetail file) {
    final fileName =
        file.originalName ?? file.fileUrl.split('/').last.split('?').first;
    showDialog(
      context: context,
      builder: (_) => _FilePreviewDialog(
        fileUrl: file.fileUrl,
        fileName: fileName,
        fileType: (file.fileType ?? '').toLowerCase(),
      ),
    );
  }

  Future<void> _downloadFile(SubmissionAttachmentDetail file) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      final fileName =
          file.originalName ?? file.fileUrl.split('/').last.split('?').first;
      final response = await http.get(Uri.parse(file.fileUrl));
      if (response.statusCode != 200) {
        throw Exception('ดาวน์โหลดล้มเหลว: HTTP ${response.statusCode}');
      }
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      final downloadedFile = File(filePath);
      await downloadedFile.writeAsBytes(response.bodyBytes);
      Get.back();
      if (Platform.isIOS) {
        await Share.shareXFiles([XFile(filePath)], subject: fileName);
      } else {
        var status = await Permission.storage.status;
        if (!status.isGranted) status = await Permission.storage.request();
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        String finalPath = '${downloadsDir.path}/$fileName';
        int counter = 1;
        while (await File(finalPath).exists()) {
          final ext = fileName.contains('.')
              ? fileName.substring(fileName.lastIndexOf('.'))
              : '';
          final base = fileName.contains('.')
              ? fileName.substring(0, fileName.lastIndexOf('.'))
              : fileName;
          finalPath = '${downloadsDir.path}/${base}_$counter$ext';
          counter++;
        }
        await downloadedFile.copy(finalPath);
        Get.snackbar(
          'ดาวน์โหลดสำเร็จ',
          'บันทึกไฟล์ที่ Downloads/$fileName',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      Get.snackbar(
        'เกิดข้อผิดพลาด',
        'ไม่สามารถดาวน์โหลดไฟล์ได้: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isReady = _controllerReady.value;
      final controllerOrNull = isReady ? _controller : null;

      return GestureDetector(
        onTap: () => _showDropdown.value = false,
        child: Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            title: Text(
              _subjectName ?? _pageTitle,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.black,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(LinkLianIcon.back, color: AppColors.black),
              onPressed: () => Get.back(),
            ),
            actions: controllerOrNull == null
                ? const []
                : [
                    _SubmittedDropdownButton(
                      controller: controllerOrNull,
                      isGroup: _isGroup,
                      showDropdown: _showDropdown,
                      dropdownSearch: _dropdownSearch,
                      onSelectStudent: (student) {
                        _showDropdown.value = false;
                        Get.to(
                          () => const StudentAssignmentDetailPage(),
                          arguments: {
                            'student': student,
                            'assignmentId': controllerOrNull.assignmentId,
                            'maxScore': _maxScore,
                            'isGroup': false,
                            'subjectName': _subjectName,
                          },
                          transition: Transition.rightToLeft,
                        );
                      },
                      onSelectGroup: (group) {
                        _showDropdown.value = false;
                        Get.to(
                          () => const StudentAssignmentDetailPage(),
                          arguments: {
                            'groupItem': group,
                            'assignmentId': controllerOrNull.assignmentId,
                            'maxScore': _maxScore,
                            'isGroup': true,
                            'subjectName': _subjectName,
                          },
                          transition: Transition.rightToLeft,
                        );
                      },
                    ),
                  ],
          ),
          body: controllerOrNull == null
              ? const Center(child: CircularProgressIndicator())
              : (controllerOrNull.isLoadingDetail.value
                    ? const Center(child: CircularProgressIndicator())
                    : Stack(
                        children: [
                          // ─── Main content: Header + group members + submission files ─
                          ListView(
                            padding: EdgeInsets.only(
                              left: AppSizes.md,
                              right: AppSizes.md,
                              top: AppSizes.md,
                              bottom: _hasSubmitted ? 300 : 120,
                            ),
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 20),
                              if (_isGroup) _buildGroupMemberSection(),
                              if (_isGroup) const SizedBox(height: 20),
                              if (_hasSubmitted) ...[
                                _buildSubmissionSection(),
                                const SizedBox(height: 40),
                              ],
                              if (!_hasSubmitted)
                                _buildNoSubmissionPlaceholder(),
                            ],
                          ),

                          // ─── Bottom sheet: grading only ────────────────────────
                          if (_hasSubmitted)
                            _TeacherDetailBottomSheet(
                              controller: controllerOrNull,
                              maxScore: _maxScore,
                              isUserDeleted:
                                  !_isGroup &&
                                  (_student?.isUserDeleted ?? false),
                            ),
                        ],
                      )),
        ),
      );
    });
  }

  // ─── No submission placeholder ────────────────────────────────────────────
  Widget _buildNoSubmissionPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryPalette[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryPalette[100]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              _isGroup ? 'กลุ่มนี้ยังไม่ได้ส่งงาน' : 'นักเรียนยังไม่ได้ส่งงาน',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        _buildAvatar(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _pageTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              if (_isGroup)
                Text(
                  '${_groupItem?.members.length ?? 0} สมาชิก',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                )
              else if (_submittedAt != null)
                Row(
                  children: [
                    Icon(Icons.access_time, size: 13, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      'ส่งงานวันที่ ${_formatDateTime(_submittedAt!)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
            ],
          ),
        ),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildAvatar() {
    if (_isGroup) {
      final name = _groupItem?.groupName ?? '';
      return CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.primaryPalette[200],
        child: Text(
          name.isNotEmpty ? name[0] : 'G',
          style: TextStyle(
            color: AppColors.primaryPalette[700],
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      );
    }
    if (_student?.isUserDeleted == true) {
      return Container(
        width: 52,
        height: 52,
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
    if (_student?.profilePic != null && _student!.profilePic!.isNotEmpty) {
      return CircleAvatar(
        radius: 26,
        backgroundImage: NetworkImage(_student!.profilePic!),
        backgroundColor: AppColors.primaryPalette[100],
      );
    }
    final initial = _student?.firstName.isNotEmpty == true
        ? _student!.firstName[0]
        : '?';
    return CircleAvatar(
      radius: 26,
      backgroundColor: AppColors.primaryPalette[200],
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.primaryPalette[700],
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (!_hasSubmitted) {
      return _badge(
        'ยังไม่ส่ง',
        Colors.grey.shade100,
        Colors.grey.shade300,
        Colors.grey.shade600,
      );
    }
    if (_markedAt != null) {
      return _badge(
        'ให้คะแนนแล้ว',
        Colors.green.shade50,
        Colors.green.shade200,
        Colors.green.shade700,
      );
    }
    return _badge(
      'ส่งแล้ว',
      AppColors.primaryPalette[50] ?? Colors.orange.shade50,
      AppColors.primaryPalette[300] ?? Colors.orange.shade300,
      AppColors.primaryPalette[700] ?? Colors.orange.shade700,
    );
  }

  Widget _badge(String label, Color bg, Color border, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: text,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ─── Group Member Section ─────────────────────────────────────────────────
  Widget _buildGroupMemberSection() {
    final members = _groupItem?.members ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'สมาชิกในกลุ่ม',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryPalette[800],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.primaryPalette[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: members.asMap().entries.map((entry) {
              final i = entry.key;
              final m = entry.value;
              final isDeleted = m['user_sys_id'] == null;
              final pic = m['profile_pic'] as String?;
              final first = m['first_name'] as String? ?? '';
              final last = m['last_name'] as String? ?? '';
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        isDeleted
                            ? Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE5E7EB),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LinkLianIcon.userOff,
                                  size: 18,
                                  color: Color(0xFF9CA3AF),
                                ),
                              )
                            : (pic != null && pic.isNotEmpty
                                  ? CircleAvatar(
                                      radius: 18,
                                      backgroundImage: NetworkImage(pic),
                                    )
                                  : CircleAvatar(
                                      radius: 18,
                                      backgroundColor:
                                          AppColors.primaryPalette[200],
                                      child: Text(
                                        first.isNotEmpty ? first[0] : '?',
                                        style: TextStyle(
                                          color: AppColors.primaryPalette[700],
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )),
                        const SizedBox(width: 10),
                        Text(
                          isDeleted
                              ? 'ไม่มีบัญชีผู้ใช้งาน'
                              : '$first $last'.trim(),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDeleted
                                ? Colors.grey[500]
                                : AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < members.length - 1)
                    Divider(height: 1, color: Colors.grey[200], indent: 50),
                ],
              );
            }).toList(),
          ),
        ),
        if (_isGroup && _submittedAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 13, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  'ส่งงานวันที่ ${_formatDateTime(_submittedAt!)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ─── Submission Files Section ──────────────────────────────────────────────
  Widget _buildSubmissionSection() {
    final detail = _controller.submissionDetail.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'งานที่ส่ง',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryPalette[800],
          ),
        ),
        const SizedBox(height: 12),
        if (detail == null)
          const Center(child: CircularProgressIndicator())
        else if (detail.attachments.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryPalette[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'ไม่มีไฟล์แนบ',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ),
          )
        else
          ...detail.attachments.map(
            (file) => InkWell(
              onTap: () => _openFilePreview(file),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      _fileIcon(file.fileType),
                      size: 28,
                      color: AppColors.primaryPalette[500],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.originalName ?? 'ไม่ทราบชื่อไฟล์',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (file.fileSize != null)
                            Text(
                              _formatFileSize(file.fileSize),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _openFilePreview(file),
                      icon: Icon(
                        Icons.visibility_outlined,
                        color: AppColors.primaryPalette[400],
                      ),
                      tooltip: 'ดูไฟล์',
                    ),
                    IconButton(
                      onPressed: () => _downloadFile(file),
                      icon: Icon(
                        Icons.download_outlined,
                        color: AppColors.primaryPalette[500],
                      ),
                      tooltip: 'ดาวน์โหลด',
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Teacher Detail Bottom Sheet (grading only) ──────────────────────────────
class _TeacherDetailBottomSheet extends StatefulWidget {
  final TeacherSubmissionController controller;
  final double? maxScore;
  final bool isUserDeleted;

  const _TeacherDetailBottomSheet({
    required this.controller,
    required this.maxScore,
    this.isUserDeleted = false,
  });

  @override
  State<_TeacherDetailBottomSheet> createState() =>
      _TeacherDetailBottomSheetState();
}

class _TeacherDetailBottomSheetState extends State<_TeacherDetailBottomSheet> {
  final _scoreTextController = TextEditingController();
  final _feedbackTextController = TextEditingController();
  bool _didPrefill = false;

  @override
  void dispose() {
    _scoreTextController.dispose();
    _feedbackTextController.dispose();
    super.dispose();
  }

  void _prefill() {
    if (_didPrefill) return;
    _didPrefill = true;
    if (widget.controller.scoreController.value.isNotEmpty) {
      _scoreTextController.text = widget.controller.scoreController.value;
    }
    if (widget.controller.feedbackController.value.isNotEmpty) {
      _feedbackTextController.text = widget.controller.feedbackController.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.38,
      minChildSize: 0.12,
      maxChildSize: 0.65,
      builder: (context, scrollController) {
        return Obx(() {
          _prefill();

          // Resolve max score: prefer from submissionDetail, then from widget arg
          final resolvedMaxScore =
              widget.controller.submissionDetail.value?.maxScore != null
              ? (widget.controller.submissionDetail.value!.maxScore is double
                    ? widget.controller.submissionDetail.value!.maxScore
                          as double
                    : (widget.controller.submissionDetail.value!.maxScore
                              as num)
                          .toDouble())
              : widget.maxScore;
          final maxScoreDisplay =
              resolvedMaxScore != null && resolvedMaxScore > 0
              ? (resolvedMaxScore % 1 == 0
                    ? resolvedMaxScore.toInt().toString()
                    : resolvedMaxScore.toString())
              : '-';
          final isGrading = widget.controller.isGrading.value;

          return Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 12),
                // Drag handle
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text(
                        'ข้อเสนอแนะ / คะแนน',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      if (widget.isUserDeleted) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            'ไม่สามารถให้คะแนนได้',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Feedback field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _feedbackTextController,
                    onChanged: widget.isUserDeleted
                        ? null
                        : (v) => widget.controller.feedbackController.value = v,
                    enabled: !widget.isUserDeleted,
                    maxLines: 4,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.isUserDeleted
                          ? Colors.grey[400]
                          : AppColors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'ข้อเสนอแนะ...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: widget.isUserDeleted
                          ? Colors.grey[50]
                          : AppColors.white,
                      contentPadding: const EdgeInsets.all(12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: widget.isUserDeleted
                              ? Colors.grey[300]!
                              : AppColors.primaryPalette[300]!,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.primaryPalette[500]!,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Score + Grade button row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 44,
                        decoration: BoxDecoration(
                          color: widget.isUserDeleted
                              ? Colors.grey[50]
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.isUserDeleted
                                ? Colors.grey[200]!
                                : AppColors.primaryPalette[300]!,
                          ),
                        ),
                        child: TextField(
                          controller: _scoreTextController,
                          onChanged: widget.isUserDeleted
                              ? null
                              : (v) =>
                                    widget.controller.scoreController.value = v,
                          enabled: !widget.isUserDeleted,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: widget.isUserDeleted
                                ? Colors.grey[400]
                                : AppColors.black,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '/ $maxScoreDisplay',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 110,
                        child: ElevatedButton(
                          onPressed: (isGrading || widget.isUserDeleted)
                              ? null
                              : widget.controller.gradeSubmission,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.isUserDeleted
                                ? Colors.grey[300]
                                : AppColors.primaryPalette[500],
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            elevation: 0,
                          ),
                          child: isGrading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'ให้คะแนน',
                                  style: TextStyle(
                                    color: widget.isUserDeleted
                                        ? Colors.grey[500]
                                        : Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        });
      },
    );
  }
}

// ─── Submitted Dropdown Button ────────────────────────────────────────────────
class _SubmittedDropdownButton extends StatefulWidget {
  final TeacherSubmissionController controller;
  final bool isGroup;
  final RxBool showDropdown;
  final RxString dropdownSearch;
  final void Function(StudentSubmissionStatusModel) onSelectStudent;
  final void Function(GroupSubmissionItem) onSelectGroup;

  const _SubmittedDropdownButton({
    required this.controller,
    required this.isGroup,
    required this.showDropdown,
    required this.dropdownSearch,
    required this.onSelectStudent,
    required this.onSelectGroup,
  });

  @override
  State<_SubmittedDropdownButton> createState() =>
      _SubmittedDropdownButtonState();
}

class _SubmittedDropdownButtonState extends State<_SubmittedDropdownButton> {
  OverlayEntry? _overlayEntry;
  final _buttonKey = GlobalKey();

  void _toggleDropdown() {
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }
    _showOverlay();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    widget.showDropdown.value = false;
  }

  void _showOverlay() {
    widget.dropdownSearch.value = '';
    widget.showDropdown.value = true;

    final renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Obx(() {
        if (!widget.showDropdown.value) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _removeOverlay());
          return const SizedBox.shrink();
        }

        final keyword = widget.dropdownSearch.value.toLowerCase();

        final submittedStudents = widget.isGroup
            ? <StudentSubmissionStatusModel>[]
            : widget.controller.allStudents
                  .where((s) => s.hasSubmitted)
                  .where(
                    (s) =>
                        keyword.isEmpty ||
                        s.displayName.toLowerCase().contains(keyword),
                  )
                  .toList();

        final submittedGroups = widget.isGroup
            ? widget.controller.groupedList
                  .where((g) => g.hasSubmitted)
                  .where(
                    (g) =>
                        keyword.isEmpty ||
                        g.groupName.toLowerCase().contains(keyword) ||
                        g.members.any((m) {
                          final label = m['user_sys_id'] == null
                              ? 'ไม่มีบัญชีผู้ใช้งาน'
                              : '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'
                                    .trim();
                          return label.toLowerCase().contains(keyword);
                        }),
                  )
                  .toList()
            : <GroupSubmissionItem>[];

        final itemCount = widget.isGroup
            ? submittedGroups.length
            : submittedStudents.length;

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _removeOverlay,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              top: offset.dy + size.height + 4,
              right: 8,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                shadowColor: Colors.black26,
                child: Container(
                  width: 260,
                  constraints: const BoxConstraints(maxHeight: 340),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: Colors.green.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.isGroup
                                  ? 'กลุ่มที่ส่งแล้ว ($itemCount)'
                                  : 'ส่งแล้ว ($itemCount คน)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: TextField(
                          onChanged: (v) => widget.dropdownSearch.value = v,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: widget.isGroup
                                ? 'ค้นหากลุ่ม...'
                                : 'ค้นหานักเรียน...',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey[400],
                              size: 18,
                            ),
                            filled: true,
                            fillColor: AppColors.primaryPalette[50],
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color:
                                    AppColors.primaryPalette[300] ??
                                    Colors.orange.shade300,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      if (itemCount == 0)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'ไม่พบรายการ',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: itemCount,
                            separatorBuilder: (_, _) => Divider(
                              height: 1,
                              color: Colors.grey.shade100,
                              indent: 48,
                            ),
                            itemBuilder: (_, i) {
                              if (widget.isGroup) {
                                final g = submittedGroups[i];
                                return _DropdownGroupTile(
                                  group: g,
                                  onTap: () {
                                    _removeOverlay();
                                    widget.onSelectGroup(g);
                                  },
                                );
                              } else {
                                final s = submittedStudents[i];
                                return _DropdownStudentTile(
                                  student: s,
                                  onTap: () {
                                    _removeOverlay();
                                    widget.onSelectStudent(s);
                                  },
                                );
                              }
                            },
                          ),
                        ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: _buttonKey,
      icon: Icon(Icons.people_outline, color: AppColors.primaryPalette[600]),
      onPressed: _toggleDropdown,
    );
  }
}

// ─── Dropdown Student Tile ────────────────────────────────────────────────────
class _DropdownStudentTile extends StatelessWidget {
  final StudentSubmissionStatusModel student;
  final VoidCallback onTap;

  const _DropdownStudentTile({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            student.isUserDeleted
                ? Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE5E7EB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LinkLianIcon.userOff,
                      size: 18,
                      color: Color(0xFF9CA3AF),
                    ),
                  )
                : student.profilePic != null && student.profilePic!.isNotEmpty
                ? CircleAvatar(
                    radius: 17,
                    backgroundImage: NetworkImage(student.profilePic!),
                  )
                : CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.primaryPalette[200],
                    child: Text(
                      student.firstName.isNotEmpty ? student.firstName[0] : '?',
                      style: TextStyle(
                        color: AppColors.primaryPalette[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                student.displayName,
                style: TextStyle(
                  fontSize: 13,
                  color: student.isUserDeleted
                      ? Colors.grey[500]
                      : AppColors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (student.isGraded)
              Icon(Icons.check_circle, size: 15, color: Colors.green.shade500),
          ],
        ),
      ),
    );
  }
}

// ─── File Preview Dialog ──────────────────────────────────────────────────────
class _FilePreviewDialog extends StatefulWidget {
  final String fileUrl;
  final String fileName;
  final String fileType;

  const _FilePreviewDialog({
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
  });

  @override
  State<_FilePreviewDialog> createState() => _FilePreviewDialogState();
}

class _FilePreviewDialogState extends State<_FilePreviewDialog> {
  String? _localPdfPath;
  bool _isPdfLoading = false;
  bool _pdfLoadFailed = false;
  int _currentPage = 0;
  int _totalPages = 0;

  bool get _isImage {
    final t = widget.fileType;
    return t == 'jpg' ||
        t == 'jpeg' ||
        t == 'png' ||
        t == 'gif' ||
        t == 'webp';
  }

  bool get _isPdf => widget.fileType == 'pdf';

  @override
  void initState() {
    super.initState();
    if (_isPdf) _loadPdf();
  }

  Future<void> _loadPdf() async {
    setState(() {
      _isPdfLoading = true;
      _pdfLoadFailed = false;
    });
    try {
      final name = widget.fileUrl.split('/').last.split('?').first;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$name');
      if (!await file.exists()) {
        final response = await http.get(Uri.parse(widget.fileUrl));
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
    } catch (_) {
      if (mounted) setState(() => _isPdfLoading = false);
      if (mounted) setState(() => _pdfLoadFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: screenHeight * 0.75,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: AppColors.primaryPalette[500],
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.fileName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isPdf && _totalPages > 0) ...[
                      Text(
                        '${_currentPage + 1}/$_totalPages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isImage) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Image.network(
          widget.fileUrl,
          fit: BoxFit.contain,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (_, _, _) => const Center(
            child: Text('ไม่สามารถโหลดรูปภาพได้'),
          ),
        ),
      );
    }

    if (_isPdf) {
      if (_pdfLoadFailed) {
        return const Center(child: Text('ไม่สามารถโหลด PDF ได้'));
      }
      if (_isPdfLoading || _localPdfPath == null) {
        return const Center(child: CircularProgressIndicator());
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
        onRender: (pages) => setState(() => _totalPages = pages ?? 0),
        onPageChanged: (page, total) => setState(() {
          _currentPage = page ?? 0;
          _totalPages = total ?? 0;
        }),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'ไม่รองรับการดูไฟล์ประเภทนี้',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'กรุณาดาวน์โหลดเพื่อเปิดดู',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─── Dropdown Group Tile ──────────────────────────────────────────────────────
class _DropdownGroupTile extends StatelessWidget {
  final GroupSubmissionItem group;
  final VoidCallback onTap;

  const _DropdownGroupTile({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.primaryPalette[200],
              child: Text(
                group.groupName.isNotEmpty ? group.groupName[0] : 'G',
                style: TextStyle(
                  color: AppColors.primaryPalette[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.groupName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${group.members.length} คน',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            if (group.markedAt != null ||
                group.score != null ||
                (group.feedback?.trim().isNotEmpty ?? false))
              Icon(Icons.check_circle, size: 15, color: Colors.green.shade500),
          ],
        ),
      ),
    );
  }
}
