import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/linklian-icon.dart';
import '../controllers/assignment_submission_controller.dart';
import '../controllers/teacher_submission_controller.dart';
import '../../data/models/group_model.dart';
import '../../data/models/student_submission_status_model.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/file_viewer_page.dart';
import 'teacher_submission_list_tab.dart';

const double _kSheetMinSize = 0.25;
const double _kSheetInitialSize = 0.45;
const double _kSheetMaxSize = 0.75;

class SubmissionBottomSheet extends StatefulWidget {
  final AssignmentSubmissionController controller;

  const SubmissionBottomSheet({super.key, required this.controller});

  @override
  State<SubmissionBottomSheet> createState() => _SubmissionBottomSheetState();
}

class _SubmissionBottomSheetState extends State<SubmissionBottomSheet> {
  final DraggableScrollableController _sheetDragController =
      DraggableScrollableController();

  AssignmentSubmissionController get controller => widget.controller;

  void _onSheetVerticalDragUpdate(DragUpdateDetails details) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight <= 0) return;
    final delta = -details.delta.dy / screenHeight;
    final currentSize = _sheetDragController.size;
    final nextSize = (currentSize + delta).clamp(
      _kSheetMinSize,
      _kSheetMaxSize,
    );
    _sheetDragController.jumpTo(nextSize);
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        controller.sheetExtent.value = notification.extent;
        final percent = (notification.extent * 100).toStringAsFixed(1);
        final minPercent = (notification.minExtent * 100).toStringAsFixed(1);
        final maxPercent = (notification.maxExtent * 100).toStringAsFixed(1);
        appLog.info(
          '[BottomSheet] | Open=$percent% (min=$minPercent%, max=$maxPercent%)',
        );
        return false;
      },
      child: DraggableScrollableSheet(
        controller: _sheetDragController,
        initialChildSize: _kSheetInitialSize,
        minChildSize: _kSheetMinSize,
        maxChildSize: _kSheetMaxSize,

        builder: (context, scrollController) {
          appLog.info(
            '[BottomSheet] | showGroupTab=${controller.showGroupTab}',
            data: context,
          );
          appLog.info(
            '[BottomSheet] | isGroup=${controller.assignmentInfo.value?.isGroup}',
            data: context,
          );

          return Obx(() {
            final isStudentSubmissionTabActive =
                !controller.isTeacher &&
                controller.currentTab.value ==
                    (controller.showGroupTab ? 1 : 0);
            final actionBarReservedHeight = isStudentSubmissionTabActive
                ? 96.0 + MediaQuery.of(context).padding.bottom
                : 0.0;

            return Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
              ),
              child: Stack(
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 12),

                      // ===== Drag Handle (sticky) =====
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onVerticalDragUpdate: _onSheetVerticalDragUpdate,
                        child: Center(
                          child: Container(
                            width: 48,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ===== TAB BAR (sticky) =====
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onVerticalDragUpdate: _onSheetVerticalDragUpdate,
                        child: Row(
                          children: [
                            if (controller.showGroupTab) _tab('กลุ่ม', 0),
                            _tab('ส่งงาน', controller.showGroupTab ? 1 : 0),
                            _tab(
                              'ข้อเสนอแนะ/คะแนน',
                              controller.showGroupTab ? 2 : 1,
                            ),
                          ],
                        ),
                      ),

                      if (isStudentSubmissionTabActive) ...[
                        const SizedBox(height: 12),
                        _StudentSubmissionStickyHeader(controller: controller),
                      ] else
                        const SizedBox(height: 16),

                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: EdgeInsets.only(
                            bottom: actionBarReservedHeight,
                          ),
                          children: [
                            // ===== CONTENT =====
                            if (controller.showGroupTab)
                              switch (controller.currentTab.value) {
                                0 =>
                                  controller.isTeacher
                                      ? _TeacherGroupTab(controller: controller)
                                      : _GroupTab(controller: controller),
                                1 =>
                                  controller.isTeacher
                                      ? TeacherSubmissionListTab(
                                          controller: controller,
                                        )
                                      : _StudentSubmissionTab(
                                          controller: controller,
                                        ),
                                2 =>
                                  controller.isTeacher
                                      ? _TeacherGradingTab(
                                          controller: controller,
                                        )
                                      : _ScoreTab(controller: controller),
                                _ => const SizedBox.shrink(),
                              }
                            else
                              switch (controller.currentTab.value) {
                                0 =>
                                  controller.isTeacher
                                      ? TeacherSubmissionListTab(
                                          controller: controller,
                                        )
                                      : _StudentSubmissionTab(
                                          controller: controller,
                                        ),
                                1 =>
                                  controller.isTeacher
                                      ? _TeacherGradingTab(
                                          controller: controller,
                                        )
                                      : _ScoreTab(controller: controller),
                                _ => const SizedBox.shrink(),
                              },
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (isStudentSubmissionTabActive)
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _StudentSubmissionActionBar(),
                    ),
                ],
              ),
            );
          });
        },
      ),
    );
  }

  Widget _tab(String text, int index) {
    return Expanded(
      child: Obx(() {
        final selected = controller.currentTab.value == index;
        if (selected) {
          appLog.info('[BottomSheet] | Active tab: $text (index=$index)');
        }
        return GestureDetector(
          onTap: () => controller.currentTab.value = index,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected
                      ? AppColors.primaryPalette[600]!
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primaryPalette[600] : Colors.grey,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _StudentSubmissionStickyHeader extends StatelessWidget {
  final AssignmentSubmissionController controller;

  const _StudentSubmissionStickyHeader({required this.controller});

  String _formatDueDate(DateTime date) {
    final buddhistYear = date.year + 543;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final yearShort = (buddhistYear % 100).toString().padLeft(2, '0');
    final time = DateFormat('HH:mm').format(date);
    return '$day/$month/$yearShort $time น.';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final DateTime? submittedDate = controller.submission.value?.submittedAt;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'งานของคุณ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryPalette[800],
              ),
            ),
            if (submittedDate != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 14, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Text(
                    'ส่งแล้ว ${_formatDueDate(submittedDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    });
  }
}

class _GroupTab extends StatelessWidget {
  final AssignmentSubmissionController controller;

  _GroupTab({required this.controller});
  final TextEditingController _groupNameController = TextEditingController();

  Widget _buildAvatar(String? profilePic, String firstName, String lastName) {
    if (profilePic != null && profilePic.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(profilePic),
        onBackgroundImageError: (exception, stackTrace) {
          appLog.info('[GroupTab] | Failed to load profile pic: $profilePic');
        },
      );
    }

    final firstInitial = firstName.isNotEmpty ? firstName[0] : '?';
    final lastInitial = lastName.isNotEmpty ? lastName[0] : '';

    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primaryPalette[300],
      child: Text(
        '$firstInitial$lastInitial',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    appLog.info(
      '[GroupTab] | '
      'group=${controller.group.value != null} | '
      'students=${controller.students.length} | '
      'filtered=${controller.filteredStudents.length}',
    );

    return Obx(() {
      final isEditing = controller.isEditingGroup.value;

      if (isEditing) {
        _groupNameController.text = controller.groupName.value;
        _groupNameController.selection = TextSelection.fromPosition(
          TextPosition(offset: _groupNameController.text.length),
        );
      }

      final group = controller.group.value;

      if (group != null && !isEditing) {
        return _buildGroupDisplay(group);
      }

      return _buildGroupForm();
    });
  }

  Widget _buildGroupDisplay(GroupModel group) {
    appLog.info('👥 Group members = ${group.members}');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  group.groupName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: controller.startEditingGroup,
                icon: const Icon(LinkLianIcon.pencil, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryPalette[200],
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'สมาชิกในกลุ่ม',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryPalette[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: group.members.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey[300],
                indent: 72,
              ),
              itemBuilder: (_, index) {
                final member = group.members[index];
                final isDeleted = member.userSysId == null;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      isDeleted
                          ? Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE5E7EB),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LinkLianIcon.userOff,
                                size: 24,
                                color: Color(0xFF9CA3AF),
                              ),
                            )
                          : _buildAvatar(
                              member.profilePic,
                              member.firstName,
                              member.lastName,
                            ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isDeleted ? 'ไม่มีบัญชีผู้ใช้งาน' : member.fullName,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: isDeleted
                                ? Colors.grey[500]
                                : AppColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildGroupForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _groupNameController,
            onChanged: (v) => controller.groupName.value = v,
            decoration: InputDecoration(
              hintText: 'ชื่อกลุ่ม',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.primaryPalette[400]!,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.primaryPalette[600]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              const Text(
                'เลือกสมาชิก',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.black,
                ),
              ),
              const Spacer(),
              Obx(() {
                if (controller.isEditingGroup.value) {
                  return TextButton(
                    onPressed: controller.cancelEditingGroupWithConfirm,
                    child: const Text('ยกเลิก'),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),

          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryPalette[300],
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              onChanged: controller.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อ',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[600],
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Obx(() {
            if (controller.isStudentLoading.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (controller.students.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryPalette[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.group_off, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'ไม่พบนักเรียนในห้องเรียน',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (controller.filteredStudents.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryPalette[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'ไม่พบนักเรียนที่ค้นหา',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: AppColors.primaryPalette[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: controller.filteredStudents.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey[300],
                  indent: 72,
                ),
                itemBuilder: (_, index) {
                  final student = controller.filteredStudents[index];
                  final userId = student.userSysId;

                  appLog.info(
                    'Student[$index]: '
                    'user_sys_id=$userId (${userId.runtimeType}) → '
                    'parsed=$userId | '
                    '${student.firstName} ${student.lastName} | '
                    'isCurrentUser=${controller.isCurrentUser(userId)}',
                  );

                  final firstName = student.firstName;
                  final lastName = student.lastName;
                  final name = '$firstName $lastName';
                  final profilePic = student.profilePic;
                  final isCurrentUser = controller.isCurrentUser(userId);

                  if (isCurrentUser) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPalette[100]?.withValues(alpha: 0.5),
                      ),
                      child: Row(
                        children: [
                          _buildAvatar(profilePic, firstName, lastName),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppColors.primaryPalette[700],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryPalette[600],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Text(
                                    'คุณ',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return InkWell(
                    onTap: () {
                      appLog.info('[Choosing] Tapped on user: $userId ($name)');
                      controller.toggleStudent(userId);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          _buildAvatar(profilePic, firstName, lastName),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                          Obx(() {
                            final selected = controller.isStudentSelected(
                              userId,
                            );
                            return Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primaryPalette[600]!
                                      : Colors.grey[400]!,
                                  width: 2,
                                ),
                                color: selected
                                    ? AppColors.primaryPalette[600]
                                    : Colors.transparent,
                              ),
                              child: selected
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: Obx(() {
              final canSubmit = controller.canSubmitGroup;
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canSubmit
                      ? AppColors.primaryPalette[600]
                      : Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: canSubmit ? controller.submitGroup : null,
                child: controller.isSubmittingGroup.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'บันทึก',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: canSubmit ? Colors.white : Colors.grey[600],
                        ),
                      ),
              );
            }),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ===== Student Submission Tab =====
class _StudentSubmissionTab extends StatefulWidget {
  final AssignmentSubmissionController controller;

  const _StudentSubmissionTab({required this.controller});

  @override
  State<_StudentSubmissionTab> createState() => _StudentSubmissionTabState();
}

class _StudentSubmissionTabState extends State<_StudentSubmissionTab> {
  static const int _filePageSize = 5;
  final ScrollController _uploadedFilesScrollController = ScrollController();
  int _visibleFileCount = _filePageSize;

  AssignmentSubmissionController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _uploadedFilesScrollController.addListener(_handleFileScroll);
  }

  @override
  void dispose() {
    _uploadedFilesScrollController.removeListener(_handleFileScroll);
    _uploadedFilesScrollController.dispose();
    super.dispose();
  }

  void _handleFileScroll() {
    if (!_uploadedFilesScrollController.hasClients) return;
    final position = _uploadedFilesScrollController.position;
    if (position.pixels < position.maxScrollExtent - 80) return;

    final totalFiles = controller.uploadedFiles.length;
    if (_visibleFileCount >= totalFiles) return;

    setState(() {
      _visibleFileCount = (_visibleFileCount + _filePageSize).clamp(
        _filePageSize,
        totalFiles,
      );
    });
    appLog.info(
      '[BottomSheet] | Load more files: visible=$_visibleFileCount / total=$totalFiles',
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  IconData _fileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'link':
        return Icons.link;
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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final canModifyFiles = controller.canModifySubmissionFiles;
      const fileTileHeight = 64.0;
      const fileTileSpacing = 8.0;
      const minVisibleFileCount = 1;
      const maxVisibleFileCount = 5;
      final extent = controller.sheetExtent.value.clamp(
        _kSheetMinSize,
        _kSheetMaxSize,
      );
      final extentRange = (_kSheetMaxSize - _kSheetMinSize);
      final normalizedExtent = extentRange <= 0
          ? 1.0
          : ((extent - _kSheetMinSize) / extentRange).clamp(0.0, 1.0);
      final visibleFileCount =
          minVisibleFileCount +
          ((maxVisibleFileCount - minVisibleFileCount) * normalizedExtent)
              .round();
      final fileListHeight =
          (fileTileHeight * visibleFileCount) +
          (fileTileSpacing * (visibleFileCount - 1));
      final totalFiles = controller.uploadedFiles.length;
      final effectiveVisibleCount = totalFiles == 0
          ? 0
          : _visibleFileCount.clamp(0, totalFiles);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: controller.uploadedFiles.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPalette[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryPalette[300]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ยังไม่มีไฟล์ที่แนบ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          canModifyFiles
                              ? 'กดปุ่ม "เพิ่มไฟล์" เพื่อแนบไฟล์'
                              : 'กดปุ่ม "แก้ไขการส่งงาน" ก่อนเพิ่มไฟล์',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    height: fileListHeight,
                    child: Scrollbar(
                      controller: _uploadedFilesScrollController,
                      child: ListView.separated(
                        controller: _uploadedFilesScrollController,
                        primary: false,
                        physics: const ClampingScrollPhysics(),
                        itemCount: effectiveVisibleCount,
                        itemBuilder: (_, index) {
                          final file = controller.uploadedFiles[index];
                          final originalName =
                              file['original_name'] ?? 'unknown';
                          final fileType = file['file_type'] ?? '';
                          final fileSize = file['file_size'] as int? ?? 0;
                          final isUploading = file['is_uploading'] == true;
                          final fileUrl = file['file_url'] as String?;

                          return _buildFileTile(
                            originalName: originalName,
                            fileType: fileType,
                            fileSize: fileSize,
                            isUploading: isUploading,
                            canModifyFiles: canModifyFiles,
                            onRemove: () => controller.removeFile(index),
                            fileUrl: fileUrl,
                          );
                        },
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: fileTileSpacing),
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 8),
        ],
      );
    });
  }

  Widget _buildFileTile({
    required String originalName,
    required String fileType,
    required int fileSize,
    required bool isUploading,
    required bool canModifyFiles,
    required VoidCallback onRemove,
    String? fileUrl,
  }) {
    return GestureDetector(
      onTap: (!isUploading && fileUrl != null && fileUrl.isNotEmpty)
          ? () => FileViewerPage.open(
                fileUrl: fileUrl,
                fileName: originalName,
                fileType: fileType,
              )
          : null,
      child: SizedBox(
      height: 64,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryPalette[300]!, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryPalette[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _fileIcon(fileType),
                color: AppColors.primaryPalette[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    originalName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isUploading
                        ? 'กำลังอัปโหลด...'
                        : (fileSize > 0
                              ? _formatFileSize(fileSize)
                              : fileType.toUpperCase()),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            if (isUploading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (canModifyFiles)
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.dangerPalette[100],
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.dangerPalette[500],
                  ),
                ),
              )
            else
              const SizedBox(width: 28, height: 28),
          ],
        ),
      ),
    ));
  }
}

class _StudentSubmissionActionBar extends StatelessWidget {
  const _StudentSubmissionActionBar();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AssignmentSubmissionController>();
    return Obx(() {
      final hasSubmission = controller.submission.value != null;
      final isSubmitting = controller.isSubmittingWork.value;
      final isEditing = controller.isEditingSubmission.value;
      final canModifyFiles = controller.canModifySubmissionFiles;
      final canSubmitNew = !hasSubmission;
      final canSaveEdit = hasSubmission && isEditing;
      final canSubmitAction =
          !isSubmitting &&
          !controller.hasUploadingFiles &&
          controller.uploadedFiles.isNotEmpty &&
          (canSubmitNew || canSaveEdit);

      return Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              Flexible(
                child: OutlinedButton.icon(
                  onPressed: (!canModifyFiles || isSubmitting)
                      ? null
                      : () =>
                            _showStudentAddAttachmentSheet(context, controller),
                  icon: Icon(
                    Icons.add,
                    size: 18,
                    color: (!canModifyFiles || isSubmitting)
                        ? Colors.grey[400]
                        : AppColors.primaryPalette[600],
                  ),
                  label: Text(
                    'เพิ่มไฟล์',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: (!canModifyFiles || isSubmitting)
                          ? Colors.grey[400]
                          : AppColors.primaryPalette[600],
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: (!canModifyFiles || isSubmitting)
                          ? Colors.grey[300]!
                          : AppColors.primaryPalette[600]!,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: ElevatedButton(
                  onPressed: hasSubmission && !isEditing
                      ? controller.startEditingSubmission
                      : (canSubmitAction
                            ? () => controller.submitWork()
                            : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (hasSubmission && !isEditing)
                        ? AppColors.primaryPalette[600]
                        : (canSubmitAction
                              ? AppColors.primaryPalette[600]
                              : Colors.grey[300]),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    elevation: 0,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          hasSubmission
                              ? (isEditing
                                    ? 'บันทึกการแก้ไข'
                                    : 'แก้ไขการส่งงาน')
                              : 'ส่งงาน',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                (hasSubmission && !isEditing) || canSubmitAction
                                ? Colors.white
                                : Colors.grey[600],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

Future<void> _showStudentAddAttachmentSheet(
  BuildContext context,
  AssignmentSubmissionController controller,
) async {
  final parentContext = context;
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[350],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Icon(
                  Icons.attach_file,
                  color: AppColors.primaryPalette[600],
                ),
                title: const Text(
                  'เพิ่มไฟล์',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Get.back();
                  controller.pickFiles();
                },
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primaryPalette[600],
                ),
                title: const Text(
                  'เพิ่มรูป',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Get.back();
                  controller.pickImageFiles();
                },
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Icon(Icons.link, color: AppColors.primaryPalette[600]),
                title: const Text(
                  'เพิ่มลิงก์',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Get.back();
                  _showStudentAddLinkDialog(parentContext, controller);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _showStudentAddLinkDialog(
  BuildContext context,
  AssignmentSubmissionController controller,
) async {
  final linkController = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('เพิ่มลิงก์'),
        content: TextField(
          controller: linkController,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(hintText: 'https://example.com'),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () {
              controller.addLinkAttachment(linkController.text);
              Get.back();
            },
            child: const Text('เพิ่ม'),
          ),
        ],
      );
    },
  );
}

// ===== Teacher Group Tab (Accordion View) =====
class _TeacherGroupTab extends StatelessWidget {
  final AssignmentSubmissionController controller;

  const _TeacherGroupTab({required this.controller});

  Widget _buildAvatar(String? profilePic, String firstName, String lastName) {
    if (profilePic != null && profilePic.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(profilePic),
        onBackgroundImageError: (exception, stackTrace) {
          appLog.info('[Group Tab] | Failed to load profile pic: $profilePic');
        },
      );
    }
    final firstInitial = firstName.isNotEmpty ? firstName[0] : '?';
    final lastInitial = lastName.isNotEmpty ? lastName[0] : '';
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.primaryPalette[300],
      child: Text(
        '$firstInitial$lastInitial',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingGroups.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (controller.allGroups.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.group_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'ยังไม่มีนักเรียนสร้างกลุ่ม',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'กลุ่มทั้งหมด (${controller.allGroups.length} กลุ่ม)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 12),
            ...controller.allGroups.map((group) {
              final members = group.members;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: AppColors.primaryPalette[300]!,
                    width: 1,
                  ),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  childrenPadding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 12,
                  ),
                  title: Row(
                    children: [
                      Icon(
                        Icons.group,
                        color: AppColors.primaryPalette[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          group.groupName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4, left: 32),
                    child: Text(
                      '${members.length} คน',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ),
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    ...members.asMap().entries.map((entry) {
                      final index = entry.key;
                      final member = entry.value;
                      final isDeleted = member.userSysId == null;
                      return Container(
                        margin: EdgeInsets.only(
                          bottom: index < members.length - 1 ? 8 : 0,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPalette[50],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            isDeleted
                                ? Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE5E7EB),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      LinkLianIcon.userOff,
                                      size: 20,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  )
                                : _buildAvatar(
                                    member.profilePic,
                                    member.firstName,
                                    member.lastName,
                                  ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isDeleted
                                    ? 'ไม่มีบัญชีผู้ใช้งาน'
                                    : member.fullName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDeleted
                                      ? Colors.grey[500]
                                      : AppColors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
            const SizedBox(height: 80),
          ],
        ),
      );
    });
  }
}

// ===== Score / Feedback Tab (Student view) =====
class _ScoreTab extends StatelessWidget {
  final AssignmentSubmissionController controller;

  const _ScoreTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final submission = controller.submission.value;
      final maxScore = controller.assignmentInfo.value?.maxScore;
      final score = submission?.score;
      final feedback = submission?.feedback;
      final markedAt = submission?.markedAt;
      final isGroupAssignment =
          controller.assignmentInfo.value?.isGroup == true;
      final groupName = submission?.groupName;

      final maxScoreDisplay = maxScore != null
          ? (maxScore % 1 == 0
                ? maxScore.toInt().toString()
                : maxScore.toString())
          : '-';

      if (score == null && (feedback == null || feedback.isEmpty)) {
        return Padding(
          padding: const EdgeInsets.all(48),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.grading_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'ยังไม่มีคะแนน',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ครูยังไม่ได้ให้คะแนนงานนี้',
                  style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (score != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 0, 20),
                decoration: BoxDecoration(
                  color: AppColors.primaryPalette[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'คะแนนที่ได้',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              score % 1 == 0
                                  ? score.toInt().toString()
                                  : score.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryPalette[700],
                              ),
                            ),
                            Text(
                              ' / $maxScoreDisplay',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (isGroupAssignment)
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.4,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Text(
                                (groupName != null &&
                                        groupName.trim().isNotEmpty)
                                    ? groupName
                                    : 'กลุ่มของคุณ',
                                textAlign: TextAlign.right,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.black,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

            if (feedback != null && feedback.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'ข้อเสนอแนะ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryPalette[800],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  feedback,
                  style: const TextStyle(fontSize: 14, color: AppColors.black),
                ),
              ),
            ],

            if (markedAt != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 14, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Text(
                    'ให้คะแนนเมื่อ ${DateFormat('dd/MM/yy HH:mm น.', 'th').format(markedAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.green[600]),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      );
    });
  }
}

// ===== Teacher Grading Tab =====
// ✅ FIX 1: ย้าย Get.isRegistered check ออกนอก Obx → ป้องกัน "improper use of GetX" error
// ✅ FIX 2: access tc.allStudents / tc.groupedList / tc.isLoading ใน Obx โดยตรง → reactive ถูกต้อง
class _TeacherGradingTab extends StatelessWidget {
  final AssignmentSubmissionController controller;

  const _TeacherGradingTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    // ✅ FIX 1: check ก่อน build — ไม่อยู่ใน Obx เพราะไม่มี observable ให้ track
    if (!Get.isRegistered<TeacherSubmissionController>()) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.grading_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'ยังไม่มีข้อมูลคะแนน',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final tc = Get.find<TeacherSubmissionController>();
    final isGroup = controller.assignmentInfo.value?.isGroup == true;

    // ✅ FIX 2: Obx observe tc observables โดยตรง — rebuild อัตโนมัติหลัง grade
    return Obx(() {
      if (tc.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      // access ใน Obx โดยตรง ไม่ทำ local variable ก่อน Obx
      final List<dynamic> gradedItems;
      final List<dynamic> ungradedItems;

      if (isGroup) {
        gradedItems = tc.groupedList
            .where(
              (g) =>
                  g.markedAt != null ||
                  g.score != null ||
                  (g.feedback?.trim().isNotEmpty ?? false),
            )
            .toList();
        ungradedItems = tc.groupedList
            .where(
              (g) =>
                  g.hasSubmitted &&
                  g.markedAt == null &&
                  g.score == null &&
                  (g.feedback?.trim().isEmpty ?? true),
            )
            .toList();
      } else {
        gradedItems = tc.allStudents.where((s) => s.isGraded).toList();
        ungradedItems = tc.allStudents
            .where((s) => s.hasSubmitted && !s.isGraded)
            .toList();
      }

      final totalSubmitted = gradedItems.length + ungradedItems.length;

      if (totalSubmitted == 0) {
        return Padding(
          padding: const EdgeInsets.all(48),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.grading_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'ยังไม่มีนักเรียนส่งงาน',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'คะแนนจะแสดงเมื่อมีการส่งงาน',
                  style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryPalette[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryBadge(
                    label: 'ให้คะแนนแล้ว',
                    count: gradedItems.length,
                    unit: isGroup ? 'กลุ่ม' : 'คน',
                    color: Colors.green.shade600,
                  ),
                  _SummaryBadge(
                    label: 'รอให้คะแนน',
                    count: ungradedItems.length,
                    unit: isGroup ? 'กลุ่ม' : 'คน',
                    color: AppColors.primaryPalette[600]!,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (gradedItems.isNotEmpty) ...[
              Text(
                'ให้คะแนนแล้ว (${gradedItems.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 8),
              ...gradedItems.map(
                (item) => _GradingSummaryTile(
                  item: item,
                  isGroup: isGroup,
                  isGraded: true,
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (ungradedItems.isNotEmpty) ...[
              Text(
                'รอให้คะแนน (${ungradedItems.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryPalette[700],
                ),
              ),
              const SizedBox(height: 8),
              ...ungradedItems.map(
                (item) => _GradingSummaryTile(
                  item: item,
                  isGroup: isGroup,
                  isGraded: false,
                ),
              ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      );
    });
  }
}

class _SummaryBadge extends StatelessWidget {
  final String label;
  final int count;
  final String unit;
  final Color color;

  const _SummaryBadge({
    required this.label,
    required this.count,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              unit,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _GradingSummaryTile extends StatelessWidget {
  final dynamic item;
  final bool isGroup;
  final bool isGraded;

  const _GradingSummaryTile({
    required this.item,
    required this.isGroup,
    required this.isGraded,
  });

  @override
  Widget build(BuildContext context) {
    String name;
    String? subtitle;
    double? score;
    String? profilePic;

    if (isGroup) {
      final g = item as GroupSubmissionItem;
      name = g.groupName;
      subtitle = '${g.members.length} คน';
      score = g.score;
    } else {
      final s = item as StudentSubmissionStatusModel;
      name = s.displayName;
      score = s.score;
      profilePic = s.profilePic;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isGraded ? Colors.green.shade100 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          if (isGroup)
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryPalette[200],
              child: Text(
                name.isNotEmpty ? name[0] : 'G',
                style: TextStyle(
                  color: AppColors.primaryPalette[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            )
          else
            profilePic != null && profilePic.isNotEmpty
                ? CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(profilePic),
                  )
                : CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryPalette[200],
                    child: Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: TextStyle(
                        color: AppColors.primaryPalette[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.black,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
          if (isGraded && score != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                score % 1 == 0 ? '${score.toInt()}' : score.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryPalette[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryPalette[200]!),
              ),
              child: Text(
                'รอคะแนน',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryPalette[600],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
