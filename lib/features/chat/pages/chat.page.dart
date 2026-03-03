import 'package:LinkLian/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:LinkLian/features/chat/controllers/chat.controller.dart';
import 'package:LinkLian/features/chat/pages/chat.message.page.dart';
import 'package:LinkLian/data/model/chat.model.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatController _chatController = ChatController();
  List<ChatModel> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      final chats = await _chatController.getChat();
      appLog.info('Loaded chats count: ${chats.length}');

      // Sort by last_sent (most recent first)
      chats.sort((a, b) {
        if (a.lastSent == null && b.lastSent == null) return 0;
        if (a.lastSent == null) return 1;
        if (b.lastSent == null) return -1;
        return b.lastSent!.compareTo(a.lastSent!);
      });

      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'เมื่อวาน';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    } else {
      return DateFormat('dd/MM/yy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'ข้อความ',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ไม่มีข้อความ',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadChats,
                  child: ListView.separated(
                    itemCount: _chats.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF0F0F0),
                      indent: 80,
                    ),
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
                      return _buildChatItem(chat);
                    },
                  ),
                ),
    );
  }


  // Build individual chat item
  Widget _buildChatItem(ChatModel chat) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatMessagePage(chat: chat),
          ),
        );
      },
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Profile Picture with online indicator
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE0E0E0),
                      width: 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: _getAvatarColor(chat.firstName ?? ''),
                    backgroundImage: chat.profileImage != null && chat.profileImage!.isNotEmpty
                        ? NetworkImage(chat.profileImage!)
                        : null,
                    child: chat.profileImage == null || chat.profileImage!.isEmpty
                        ? (chat.firstName != null || chat.lastName != null
                            ? Text(
                                _getInitials(chat.firstName, chat.lastName),
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
                // Online indicator (optional - ถ้ามีข้อมูล online status)
                // Positioned(
                //   bottom: 2,
                //   right: 2,
                //   child: Container(
                //     width: 14,
                //     height: 14,
                //     decoration: BoxDecoration(
                //       color: Colors.green,
                //       shape: BoxShape.circle,
                //       border: Border.all(color: Colors.white, width: 2),
                //     ),
                //   ),
                // ),
              ],
            ),
            const SizedBox(width: 14),
            // Chat Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${chat.firstName ?? ''} ${chat.lastName ?? ''}'.trim(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(chat.lastSent),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage ?? 'ไม่มีข้อความ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Unread badge (optional - ถ้ามีข้อมูล unread count)
                      // if (chat.unreadCount != null && chat.unreadCount! > 0)
                      //   Container(
                      //     margin: const EdgeInsets.only(left: 8),
                      //     padding: const EdgeInsets.symmetric(
                      //       horizontal: 8,
                      //       vertical: 2,
                      //     ),
                      //     decoration: BoxDecoration(
                      //       color: Colors.red,
                      //       borderRadius: BorderRadius.circular(12),
                      //     ),
                      //     child: Text(
                      //       '${chat.unreadCount}',
                      //       style: const TextStyle(
                      //         color: Colors.white,
                      //         fontSize: 11,
                      //         fontWeight: FontWeight.w600,
                      //       ),
                      //     ),
                      //   ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
    // Generate color based on name for consistency
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