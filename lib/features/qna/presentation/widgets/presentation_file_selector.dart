import 'package:LinkLian/core/constants/colors.dart';
import 'package:LinkLian/features/qna/presentation/controllers/live_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get/get.dart';

class PresentationFileSelector extends StatelessWidget {
  final LiveController controller;
  final bool showFollow;
  final Function(Map<String, dynamic>) onFileSelected;

  const PresentationFileSelector({
    super.key,
    required this.controller,
    this.showFollow = true,
    required this.onFileSelected,
  });

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  String _sanitizeLabel(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null' || text == '-') {
      return '';
    }
    return text;
  }

  String _resolvePresentationFileLabel(Map<String, dynamic> file) {
    final attachmentId = _toInt(file['attachment_id']);

    final directName = _sanitizeLabel(file['original_name']);
    if (directName.isNotEmpty) {
      return attachmentId != null ? '$directName (#$attachmentId)' : directName;
    }

    final nestedAttachment = file['attachment'];
    if (nestedAttachment is Map) {
      final attachmentMap = Map<String, dynamic>.from(nestedAttachment);
      final nestedName = _sanitizeLabel(attachmentMap['original_name']);
      if (nestedName.isNotEmpty) {
        return attachmentId != null
            ? '$nestedName (#$attachmentId)'
            : nestedName;
      }

      final nestedFileName = _sanitizeLabel(attachmentMap['file_name']);
      if (nestedFileName.isNotEmpty) {
        return attachmentId != null
            ? '$nestedFileName (#$attachmentId)'
            : nestedFileName;
      }
    }

    final nestedPostContent = file['post_content'];
    if (nestedPostContent is Map) {
      final postContentMap = Map<String, dynamic>.from(nestedPostContent);
      final title = _sanitizeLabel(postContentMap['title']);
      if (title.isNotEmpty) {
        return attachmentId != null ? '$title (#$attachmentId)' : title;
      }
    }

    final fileName = _sanitizeLabel(file['file_name']);
    if (fileName.isNotEmpty) {
      return attachmentId != null ? '$fileName (#$attachmentId)' : fileName;
    }

    return attachmentId != null ? 'ไฟล์ (#$attachmentId)' : 'ไฟล์';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedId = _toInt(
        controller.selectedAttachment.value?['attachment_id'],
      );
      final presentationFiles = controller.liveLogFiles;

      final liveFileById = <int, Map<String, dynamic>>{};
      for (final raw in controller.liveFiles) {
        final map = Map<String, dynamic>.from(raw as Map);
        final id = _toInt(map['attachment_id']);
        if (id == null) continue;
        liveFileById[id] = map;
      }

      final selectorById = <int, Map<String, dynamic>>{};
      for (final raw in presentationFiles) {
        final map = Map<String, dynamic>.from(raw as Map);
        final id = _toInt(map['attachment_id']);
        if (id == null) continue;
        selectorById[id] = map;
      }

      if (selectorById.isEmpty) {
        final selected = controller.selectedAttachment.value;
        final selectedAttachmentId = _toInt(selected?['attachment_id']);
        if (selected != null && selectedAttachmentId != null) {
          selectorById[selectedAttachmentId] = Map<String, dynamic>.from(
            selected,
          );
        }
      }

      final selectorEntries = <Map<String, dynamic>>[];
      for (final entry in selectorById.entries) {
        final id = entry.key;
        final logItem = entry.value;

        final fromLog = <String, dynamic>{'attachment_id': id};
        final nestedAttachment = logItem['attachment'];
        if (nestedAttachment is Map) {
          fromLog.addAll(Map<String, dynamic>.from(nestedAttachment));
        }
        if (fromLog['post_id'] == null && logItem['post_id'] != null) {
          fromLog['post_id'] = logItem['post_id'];
        }

        final fromLive = liveFileById[id] ?? <String, dynamic>{};
        final effectiveAttachment = <String, dynamic>{
          ...fromLog,
          ...fromLive,
          'attachment_id': id,
        };

        if ((effectiveAttachment['file_url'] == null ||
                effectiveAttachment['file_url'].toString().trim().isEmpty) &&
            logItem['file_url'] != null) {
          effectiveAttachment['file_url'] = logItem['file_url'];
        }
        if ((effectiveAttachment['file_type'] == null ||
                effectiveAttachment['file_type'].toString().trim().isEmpty) &&
            logItem['file_type'] != null) {
          effectiveAttachment['file_type'] = logItem['file_type'];
        }
        if ((effectiveAttachment['original_name'] == null ||
                effectiveAttachment['original_name']
                    .toString()
                    .trim()
                    .isEmpty) &&
            logItem['original_name'] != null) {
          effectiveAttachment['original_name'] = logItem['original_name'];
        }

        if (effectiveAttachment['file_url'] == null ||
            effectiveAttachment['file_url'].toString().trim().isEmpty) {
          continue;
        }

        selectorEntries.add({
          'id': id,
          'log': logItem,
          'attachment': effectiveAttachment,
        });
      }

      final showFileDropdown = selectorEntries.isNotEmpty;
      final selectedValue = selectorEntries.any((e) => e['id'] == selectedId)
          ? selectedId
          : null;

      return Column(
        children: [
          Row(
            children: [
              if (showFileDropdown)
                Expanded(
                  child: Builder(
                    builder: (context) => GestureDetector(
                      onTap: () {
                        final RenderBox button =
                            context.findRenderObject() as RenderBox;
                        final RenderBox overlay =
                            Overlay.of(context).context.findRenderObject()
                                as RenderBox;
                        final buttonWidth = button.size.width;
                        final buttonPos = button.localToGlobal(
                          Offset.zero,
                          ancestor: overlay,
                        );

                        showMenu<dynamic>(
                          context: context,
                          position: RelativeRect.fromLTRB(
                            buttonPos.dx,
                            buttonPos.dy + button.size.height + 8,
                            overlay.size.width - (buttonPos.dx + buttonWidth),
                            0,
                          ),
                          constraints: BoxConstraints(minWidth: buttonWidth),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          items: selectorEntries
                              .map(
                                (entry) => PopupMenuItem<dynamic>(
                                  value: entry['id'],
                                  child: SizedBox(
                                    width: buttonWidth - 32,
                                    child: Text(
                                      _resolvePresentationFileLabel(
                                        Map<String, dynamic>.from(
                                          entry['attachment'] as Map,
                                        ),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ).then((value) {
                          if (value != null) {
                            final targetId = _toInt(value);
                            Map<String, dynamic>? pickedAttachment;

                            for (final entry in selectorEntries) {
                              if (entry['id'] == targetId) {
                                pickedAttachment = Map<String, dynamic>.from(
                                  entry['attachment'] as Map,
                                );
                                break;
                              }
                            }

                            if (pickedAttachment != null) {
                              onFileSelected(pickedAttachment);
                            }
                          }
                        });
                      },
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                selectedValue != null
                                    ? _resolvePresentationFileLabel(
                                        Map<String, dynamic>.from(
                                          selectorEntries.firstWhere(
                                                (e) => e['id'] == selectedValue,
                                              )['attachment']
                                              as Map,
                                        ),
                                      )
                                    : 'เลือกไฟล์สไลด์',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Icon(Icons.expand_more_rounded),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (showFollow) ...[
                const SizedBox(width: 8),
                Obx(
                  () => GestureDetector(
                    onTap: () =>
                        controller.setFollowing(!controller.isFollowing.value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: controller.isFollowing.value
                              ? AppColors.primaryPalette[500]!
                              : AppColors.primaryPalette[400]!,
                          width: 1.5,
                        ),
                        color: controller.isFollowing.value
                            ? AppColors.primaryPalette[500]
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!controller.isFollowing.value) ...[
                            Icon(
                              TablerIcons.presentation,
                              size: 20,
                              color: AppColors.primaryPalette[500],
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            controller.isFollowing.value
                                ? 'กำลังติดตาม'
                                : 'ติดตาม',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: controller.isFollowing.value
                                  ? Colors.white
                                  : AppColors.primaryPalette[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    });
  }
}
