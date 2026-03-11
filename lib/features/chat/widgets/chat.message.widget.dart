import 'package:flutter/material.dart';
import 'package:LinkLian/data/model/chat.model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:LinkLian/core/constants/colors.dart';

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
  final String? senderFirstName;
  final String? senderLastName;
  final String? profileImage;

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
  }) : super(key: key) {
    // Pre-compute expensive operations
    _initials = _getInitials(senderFirstName, senderLastName);
    _avatarColor = _getAvatarColor(senderFirstName ?? '');
    _timeText = message.createdAt != null
        ? _formatTime(message.createdAt!)
        : _formatTime(DateTime.now());
    _content = message.content ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
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
                  backgroundImage: profileImage != null && profileImage!.isNotEmpty
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
                          : const Icon(Icons.person, color: AppColors.white, size: 16))
                      : null,
                ),
              ),
            ],

            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isMe
                      ? AppColors.primaryPalette[100]
                      : AppColors.white,
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
                    Text(
                      _content,
                      style: TextStyle(
                        color: isMe ? AppColors.black : const Color(0xFF1A1A1A),
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


// Text input area with send button and attachment options
class ChatInputArea extends StatelessWidget {
  final TextEditingController textController;
  final VoidCallback onSend;

  const ChatInputArea({
    super.key,
    required this.textController,
    required this.onSend,
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
                // Attachment buttons - แสดงเฉพาะเมื่อไม่มีข้อความ
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
                            // Handle image attachment
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
                            // Handle link attachment
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
                        // Send button - แสดงเฉพาะเมื่อมีข้อความ
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
