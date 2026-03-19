import 'package:LinkLian/core/utils/dialog_helper.dart';
import 'package:LinkLian/features/chat/presentation/widgets/chat_attachment_widget.dart';
import 'package:flutter/material.dart';
import 'package:LinkLian/features/chat/data/models/chat.model.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:LinkLian/core/constants/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:LinkLian/features/chat/presentation/controllers/chat.message.controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

// Static formatters for better performance
class _Formatters {
  static final timeFormat = DateFormat('HH:mm');
  static final dateFormat = DateFormat('d MMMM yyyy', 'th');
}

// Chat message bubble widget
class ChatMessageBubble extends StatelessWidget {
  final ChatModel message;
  final bool isMe;
  final int? currentUserId;
  final ChatModel? replyMessage;
  final Function(ChatModel message)? onReply;
  final Function(int messageId)? onJumpToMessage;
  final String? senderFirstName;
  final String? senderLastName;
  final String? profileImage;
  final bool highlight;

  // Cache computed values
  late final String _initials;
  late final Color _avatarColor;
  late final String _timeText;
  late final String _content;

  ChatMessageBubble({
    required Key key,
    required this.message,
    required this.isMe,
    required this.currentUserId,
    this.senderFirstName,
    this.senderLastName,
    this.profileImage,
    this.replyMessage,
    this.onReply,
    this.onJumpToMessage,
    this.highlight = false,
  }) : super(key: key) {
    // Pre-compute expensive operations
    _initials = _getInitials(senderFirstName, senderLastName);
    _avatarColor = _getAvatarColor(senderFirstName ?? '');
    _timeText = message.createdAt != null
        ? _formatTime(message.createdAt!)
        : _formatTime(DateTime.now());
    _content = (message.content ?? '')
        .replaceAll('[image]', '')
        .replaceAll('[file]', '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        _showMessageMenu(context);
      },
      child: RepaintBoundary(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Profile picture for received messages
              if (!isMe) ...[
                Container(
                  margin: const EdgeInsets.only(right: 8, bottom: 2),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: _avatarColor,
                    backgroundImage:
                        profileImage != null && profileImage!.isNotEmpty
                        ? NetworkImage(profileImage!)
                        : null,
                    child: profileImage == null || profileImage!.isEmpty
                        ? (senderFirstName != null || senderLastName != null
                              ? Text(
                                  _initials,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  color: AppColors.white,
                                  size: 16,
                                ))
                        : null,
                  ),
                ),
              ],

              Flexible(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: highlight
                        ? AppColors.primaryPalette[200]
                        : (isMe
                              ? AppColors.primaryPalette[100]
                              : AppColors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isMe
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                      bottomRight: isMe
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      if (replyMessage != null)
                        GestureDetector(
                          onTap: () {
                            if (replyMessage?.messageId != null) {
                              onJumpToMessage?.call(replyMessage!.messageId!);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[200]!.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  replyMessage!.senderId == currentUserId
                                      ? "คุณ"
                                      : "${senderFirstName ?? ''}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryPalette[700]!,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  replyMessage!.content ?? "",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if ((message.file ?? []).isNotEmpty)
                        ChatAttachmentWidget.buildAttachment(
                          context,
                          message.file!.first,
                        ),

                      /// LINK PREVIEW
                      if (_content.startsWith("http") ||
                          _content.startsWith("www"))
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// CLICKABLE LINK
                            GestureDetector(
                              onTap: () async {
                                final link = _content.startsWith("http")
                                    ? _content
                                    : "https://$_content";

                                final uri = Uri.parse(link);

                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              },
                              child: Text(
                                _content,
                                style: TextStyle(
                                  color: AppColors.buttonPalette[600],
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.buttonPalette[600],
                                  decorationThickness: 0.5,
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),

                            /// PREVIEW
                            ChatAttachmentWidget.buildLinkPreview(_content),
                          ],
                        )
                      else if (_content.isNotEmpty)
                        Text(
                          _content,
                          style: TextStyle(
                            color: isMe
                                ? AppColors.black
                                : const Color(0xFF1A1A1A),
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      const SizedBox(height: 4),

                      Text(
                        _timeText,
                        style: TextStyle(
                          color: isMe
                              ? AppColors.black.withValues(alpha: 0.7)
                              : Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return _Formatters.timeFormat.format(dateTime);
  }

  static String _getInitials(String? firstName, String? lastName) {
    String initials = '';
    if (firstName != null && firstName.isNotEmpty) {
      initials += firstName.substring(0, 1).toUpperCase();
    }
    if (lastName != null && lastName.isNotEmpty) {
      initials += lastName.substring(0, 1).toUpperCase();
    }
    return initials.isNotEmpty ? initials : '?';
  }

  static Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF6C63FF),
      const Color(0xFFFF6584),
      const Color(0xFF4ECDC4),
      const Color(0xFFFFBE0B),
      const Color(0xFF8338EC),
      const Color(0xFFFF006E),
      const Color(0xFF06FFA5),
      const Color(0xFFFFAA00),
    ];

    if (name.isEmpty) return colors[0];

    final index = name.codeUnitAt(0) % colors.length;
    return colors[index];
  }

  void _showMessageMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.reply,
                  color: AppColors.primaryPalette[600],
                ),
                title: const Text('ตอบกลับข้อความ'),
                onTap: () {
                  Navigator.pop(context);
                  onReply?.call(message);
                },
              ),

              ListTile(
                leading: Icon(Icons.copy, color: AppColors.primaryPalette[600]),
                title: const Text('คัดลอกข้อความ'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.content ?? ""));

                  Navigator.pop(context);
                  DialogHelper.showNotification(
                    title: 'คัดลอกแล้ว',
                    message: 'คัดลอกข้อความเรียบร้อยแล้ว',
                    type: NotificationType.success,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Date separator widget
class ChatDateSeparator extends StatelessWidget {
  final DateTime date;
  late final String _dateText;

  ChatDateSeparator({required Key key, required this.date}) : super(key: key) {
    // Pre-compute date text
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate.isAtSameMomentAs(today)) {
      _dateText = 'วันนี้';
    } else if (messageDate.isAtSameMomentAs(yesterday)) {
      _dateText = 'เมื่อวาน';
    } else {
      _dateText = _Formatters.dateFormat.format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _dateText,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class LinkAttachDialog extends StatelessWidget {
  final Function(String url) onSubmit;

  LinkAttachDialog({super.key, required this.onSubmit});

  final TextEditingController urlController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(TablerIcons.link, color: AppColors.primaryPalette[600]),
          const SizedBox(width: 8),
          const Text("แนบลิงก์"),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: urlController,
            decoration: InputDecoration(
              hintText: "https://...",
              prefixIcon: const Icon(Icons.link),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.url,
            autofocus: true,
          ),
          const SizedBox(height: 8),
          Text(
            'ลิงก์จะแสดงเป็น preview และเปิดใน browser เมื่อกด',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("ยกเลิก")),
        ElevatedButton(
          onPressed: () {
            final url = urlController.text.trim();
            if (url.isEmpty) return;

            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              DialogHelper.showNotification(
                title: 'ลิงก์ไม่ถูกต้อง',
                message: 'กรุณาใส่ลิงก์ที่ขึ้นต้นด้วย http:// หรือ https://',
                type: NotificationType.warning,
              );
              return;
            }

            onSubmit(url);
            Get.back();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPalette[500],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            "เพิ่ม",
            style: TextStyle(color: AppColors.primaryPalette[900]),
          ),
        ),
      ],
    );
  }
}

// Text input area with send button and attachment options
class ChatInputArea extends StatelessWidget {
  final TextEditingController textController;
  final VoidCallback onSend;
  final ChatMessageController controller;

  const ChatInputArea({
    super.key,
    required this.textController,
    required this.onSend,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: textController,
          builder: (context, value, child) {
            final bool hasText = value.text.trim().isNotEmpty;

            return Row(
              children: [
                // Attachment buttons
                if (!hasText)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryPalette[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            TablerIcons.file_plus,
                            color: AppColors.primaryPalette[500],
                            size: 22,
                          ),
                          onPressed: () {
                            // Handle file attachment
                            controller.pickFile();
                          },
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          icon: Icon(
                            TablerIcons.photo_plus,
                            color: AppColors.primaryPalette[500],
                            size: 22,
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              builder: (context) => SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'เลือกรูปภาพ',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryPalette[800],
                                        ),
                                      ),

                                      const SizedBox(height: 20),

                                      ListTile(
                                        leading: Icon(
                                          Icons.photo_library,
                                          color: AppColors.primaryPalette[600],
                                        ),
                                        title: const Text('เลือกจากแกลเลอรี'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          controller.pickImage(
                                            ImageSource.gallery,
                                          );
                                        },
                                      ),

                                      ListTile(
                                        leading: Icon(
                                          Icons.camera_alt,
                                          color: AppColors.primaryPalette[600],
                                        ),
                                        title: const Text('ถ่ายรูป'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          controller.pickImage(
                                            ImageSource.camera,
                                          );
                                        },
                                      ),

                                      const SizedBox(height: 10),

                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('ยกเลิก'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },

                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          icon: Icon(
                            TablerIcons.link_plus,
                            color: AppColors.primaryPalette[500],
                            size: 22,
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => LinkAttachDialog(
                                onSubmit: (url) {
                                  controller.sendLink(url);
                                },
                              ),
                            );
                          },
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                if (!hasText) const SizedBox(width: 8),

                // Text input with send button
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryPalette[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textController,
                            decoration: const InputDecoration(
                              hintText: 'Aa...',
                              hintStyle: TextStyle(
                                color: Color(0xFFBDBDBD),
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                            ),
                            style: const TextStyle(fontSize: 15),
                            minLines: 1,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (hasText)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryPalette[500],
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  TablerIcons.send,
                                  color: AppColors.white,
                                  size: 20,
                                ),
                                onPressed: onSend,
                                padding: const EdgeInsets.all(10),
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
