import 'package:flutter/material.dart';
import 'package:LinkLian/data/model/chat.model.dart';
import 'package:LinkLian/features/chat/controllers/chat.message.controller.dart';
import 'package:LinkLian/features/chat/widgets/chat.message.widget.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class ChatMessagePage extends StatefulWidget {
  final ChatModel chat;

  const ChatMessagePage({super.key, required this.chat});

  @override
  State<ChatMessagePage> createState() => _ChatMessagePageState();
}

class _ChatMessagePageState extends State<ChatMessagePage> {
  final ChatMessageController _controller = ChatMessageController();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.chat.chatId != null) {
      _controller.init(widget.chat.chatId!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend() async {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      _textController.clear();
      await _controller.sendMessage(text);
      // Debounced scroll to bottom after sending
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          _scrollController.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: _getAvatarColor(widget.chat.firstName ?? ''),
                backgroundImage: widget.chat.profileImage != null && widget.chat.profileImage!.isNotEmpty
                    ? NetworkImage(widget.chat.profileImage!)
                    : null,
                child: widget.chat.profileImage == null || widget.chat.profileImage!.isEmpty
                    ? (widget.chat.firstName != null || widget.chat.lastName != null
                        ? Text(
                            _getInitials(
                              widget.chat.firstName,
                              widget.chat.lastName,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.chat.firstName ?? ''} ${widget.chat.lastName ?? ''}'
                        .trim(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Optional: Online status
                  // Text(
                  //   'Active now',
                  //   style: TextStyle(
                  //     color: Colors.grey[600],
                  //     fontSize: 12,
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              TablerIcons.dots_vertical,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () {
              // Show options menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatModel>>(
              stream: _controller.messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          TablerIcons.message_circle,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "เริ่มต้นการสนทนา...",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                // Auto scroll to bottom when messages first load
                if (messages.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                }

                // Debounce auto scroll to prevent excessive scrolling
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  itemCount: messages.length,
                  // Add cacheExtent for better performance
                  cacheExtent: 1000,
                  addAutomaticKeepAlives: true,
                  addRepaintBoundaries: true,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _controller.currentUserId;

                    // Check if we need to show date separator
                    bool showDateSeparator = false;
                    if (index == 0) {
                      showDateSeparator = true;
                    } else {
                      final prevMessage = messages[index - 1];
                      if (message.createdAt != null &&
                          prevMessage.createdAt != null) {
                        final currentDate = DateTime(
                          message.createdAt!.year,
                          message.createdAt!.month,
                          message.createdAt!.day,
                        );
                        final prevDate = DateTime(
                          prevMessage.createdAt!.year,
                          prevMessage.createdAt!.month,
                          prevMessage.createdAt!.day,
                        );
                        showDateSeparator = !currentDate.isAtSameMomentAs(
                          prevDate,
                        );
                      }
                    }

                    return Column(
                      key: ValueKey('message_${message.messageId}_${index}'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showDateSeparator)
                          ChatDateSeparator(
                            key: ValueKey('date_${message.createdAt?.day}_${message.createdAt?.month}'),
                            date: message.createdAt ?? DateTime.now(),
                          ),
                        ChatMessageBubble(
                          key: ValueKey('bubble_${message.messageId ?? index}'),
                          message: message,
                          isMe: isMe,
                          currentUserId: _controller.currentUserId,
                          senderFirstName: widget.chat.firstName,
                          senderLastName: widget.chat.lastName,
                          profileImage: widget.chat.profileImage,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          ChatInputArea(
            textController: _textController,
            onSend: _handleSend,
          ),
        ],
      ),
    );
  }

  String _getInitials(String? firstName, String? lastName) {
    String initials = '';
    if (firstName != null && firstName.isNotEmpty) {
      initials += firstName.substring(0, 1).toUpperCase();
    }
    if (lastName != null && lastName.isNotEmpty) {
      initials += lastName.substring(0, 1).toUpperCase();
    }
    return initials.isNotEmpty ? initials : '?';
  }

  Color _getAvatarColor(String name) {
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
