import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/linklian-icon.dart';
import '../controllers/assignment_submission_controller.dart';
import '../../data/models/group_model.dart';
import '../../../../core/utils/logger.dart';

class SubmissionBottomSheet extends StatelessWidget {
  final AssignmentSubmissionController controller;

  const SubmissionBottomSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.18,
      maxChildSize: 0.90,

      builder: (context, scrollController) {
        appLog.info(
          '🔍 BottomSheet build | showGroupTab=${controller.showGroupTab}',
        );
        appLog.info(
          '🔍 isGroup=${controller.assignmentInfo.value?.isGroup}',
        );

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

              // ===== Drag Handle =====
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

              const SizedBox(height: 12),

              // ===== TAB BAR =====
              Row(
                children: [
                  if (controller.showGroupTab) _tab('กลุ่ม', 0),
                  _tab('ส่งงาน', controller.showGroupTab ? 1 : 0),
                  _tab('คะแนน', controller.showGroupTab ? 2 : 1),
                ],
              ),

              const SizedBox(height: 16),

              // ===== CONTENT =====
Obx(() {
  if (controller.showGroupTab) {
    // งานกลุ่ม: มี 3 แท็บ (กลุ่ม, ส่งงาน, คะแนน)
    switch (controller.currentTab.value) {
      case 0:
        return controller.isTeacher
            ? _TeacherGroupTab(controller: controller)
            : _GroupTab(controller: controller);
      case 1:
        return controller.isTeacher
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('ส่งงาน (ครู)')),
              )
            : _StudentSubmissionTab(controller: controller);
      case 2:
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('คะแนน')),
        );
      default:
        return const SizedBox.shrink();
    }
  } else {
    // งานเดี่ยว: มี 2 แท็บ (ส่งงาน, คะแนน)
    switch (controller.currentTab.value) {
      case 0:
        return controller.isTeacher
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('ส่งงาน (ครู)')),
              )
            : _StudentSubmissionTab(controller: controller);
      case 1:
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('คะแนน')),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}),
            ],
          ),
        );
      },
    );
  }

  Widget _tab(String text, int index) {
    return Expanded(
      child: Obx(() {
        final selected = controller.currentTab.value == index;
        // Debug log
        if (selected) {
          appLog.info('📍 Active tab: $text (index=$index)');
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

class _GroupTab extends StatelessWidget {
  final AssignmentSubmissionController controller;

  _GroupTab({required this.controller});
  final TextEditingController _groupNameController = TextEditingController();

  int? _parseUserId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Widget _buildAvatar(String? profilePic, String firstName, String lastName) {
    if (profilePic != null && profilePic.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(profilePic),
        onBackgroundImageError: (exception, stackTrace) {
          appLog.info('⚠️ Failed to load profile pic: $profilePic');
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
      '🧩 GroupTab build | '
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

      // ===============================
      // มีกลุ่มแล้ว และไม่ได้อยู่ใน edit mode
      // ===============================
      if (group != null && !isEditing) {
        return _buildGroupDisplay(group);
      }

      // ===============================
      // ยังไม่มีกลุ่ม หรือกำลัง edit
      // ===============================
      return _buildGroupForm();
    });
  }

  // ===== UI แสดงกลุ่ม (หลังสร้างเสร็จ) =====
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.black),
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
              separatorBuilder: (_, __) => Divider(height: 1, thickness: 1, color: Colors.grey[300], indent: 72),
              itemBuilder: (_, index) {
                final member = group.members[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      _buildAvatar(member.profilePic, member.firstName, member.lastName),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          member.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
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

  // ===== UI Form สร้าง/แก้ไขกลุ่ม =====
  Widget _buildGroupForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== ชื่อกลุ่ม =====
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

          // ===== Label + ปุ่ม Cancel =====
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

          // ===== Search Bar =====
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

          // ===== Member List =====
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
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey[300],
                  indent: 72,
                ),
                itemBuilder: (_, index) {
                  final student = controller.filteredStudents[index];

                  final userIdDynamic = student['user_sys_id'];
                  final userId = _parseUserId(userIdDynamic);

                  if (userId == null) {
                    return const SizedBox.shrink();
                  }

                  final firstName = student['first_name'] ?? '';
                  final lastName = student['last_name'] ?? '';
                  final name = '$firstName $lastName';
                  final profilePic = student['profile_pic'] as String?;
                  final isCurrentUser = controller.isCurrentUser(userId);

                  if (isCurrentUser) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPalette[100]?.withOpacity(0.5),
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
                      appLog.info('👆 Tapped on user: $userId ($name)');
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

          // ===== Save Button =====
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
class _StudentSubmissionTab extends StatelessWidget {
  final AssignmentSubmissionController controller;

  const _StudentSubmissionTab({required this.controller});

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDueDate(DateTime date) {
    final buddhistYear = date.year + 543;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final yearShort = (buddhistYear % 100).toString().padLeft(2, '0');
    final time = DateFormat('HH:mm').format(date);
    return '$day/$month/$yearShort $time น.';
  }

  IconData _fileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
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
      final hasSubmission = controller.existingSubmission.value != null;
      final isSubmitting = controller.isSubmittingWork.value;

      // ===== แสดงเวลาที่ส่งงาน =====
      final submittedAt = controller.existingSubmission.value?['submitted_at'];
      DateTime? submittedDate;
      if (submittedAt != null) {
        submittedDate = submittedAt is DateTime
            ? submittedAt
            : DateTime.tryParse(submittedAt.toString());
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Header: งานของคุณ + เวลาที่ส่ง =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
          ),

          const SizedBox(height: 16),

          // ===== File list =====
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
                          'กดปุ่ม "เพิ่มไฟล์" เพื่อแนบไฟล์',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: controller.uploadedFiles.asMap().entries.map((entry) {
                      final file = entry.value;
                      final originalName = file['original_name'] ?? 'unknown';
                      final fileType = file['file_type'] ?? '';
                      final fileSize = file['file_size'] as int? ?? 0;
                      final isUploading = file['is_uploading'] == true;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryPalette[300]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // File icon
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

                            // File name + size
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
                                    fileSize > 0
                                        ? _formatFileSize(fileSize)
                                        : fileType.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Uploading indicator or remove button
                            if (isUploading)
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              GestureDetector(
                                onTap: () => controller.removeFile(entry.key),
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
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),

          const SizedBox(height: 24),

          // ===== Bottom: เพิ่มไฟล์ + ส่งงาน =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                // เพิ่มไฟล์ button
                Flexible(
                  child: OutlinedButton.icon(
                    onPressed: isSubmitting ? null : () => controller.pickFiles(),
                    icon: Icon(
                      Icons.add,
                      size: 18,
                      color: isSubmitting
                          ? Colors.grey[400]
                          : AppColors.primaryPalette[600],
                    ),
                    label: Text(
                      'เพิ่มไฟล์',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSubmitting
                            ? Colors.grey[400]
                            : AppColors.primaryPalette[600],
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isSubmitting
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

                // ส่งงาน button
                Flexible(
                  child: ElevatedButton(
                    onPressed: (isSubmitting || controller.uploadedFiles.isEmpty)
                        ? null
                        : () => controller.submitWork(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: controller.uploadedFiles.isEmpty
                          ? Colors.grey[300]
                          : AppColors.primaryPalette[600],
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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            hasSubmission ? 'ส่งงานอีกครั้ง' : 'ส่งงาน',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: controller.uploadedFiles.isEmpty
                                  ? Colors.grey[600]
                                  : Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
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
          appLog.info('⚠️ Failed to load profile pic: $profilePic');
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
                Icon(
                  Icons.group_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
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
            // ===== Header =====
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
                  side: BorderSide(color: AppColors.primaryPalette[300]!, width: 1),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                  title: Row(
                    children: [
                      Icon(Icons.group, color: AppColors.primaryPalette[600], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          group.groupName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.black),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4, left: 32),
                    child: Text('${members.length} คน', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ),
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    ...members.asMap().entries.map((entry) {
                      final index = entry.key;
                      final member = entry.value;
                      return Container(
                        margin: EdgeInsets.only(bottom: index < members.length - 1 ? 8 : 0),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPalette[50],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            _buildAvatar(member.profilePic, member.firstName, member.lastName),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                member.fullName,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.black),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 80),
          ],
        ),
      );
    });
  }
}