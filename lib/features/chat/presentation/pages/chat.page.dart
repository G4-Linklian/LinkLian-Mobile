import 'package:LinkLian/core/constants/colors.dart';
import 'package:LinkLian/core/services/local_storage.dart';
import 'package:LinkLian/core/utils/logger.dart';
import 'package:LinkLian/features/auth/controller/auth_controller.dart';
import 'package:LinkLian/features/chat/presentation/pages/ai_chat_list.page.dart';
import 'package:flutter/material.dart';
import 'package:LinkLian/features/chat/presentation/controllers/chat.controller.dart';
import 'package:LinkLian/features/chat/presentation/pages/chat.message.page.dart';
import 'package:LinkLian/features/chat/data/models/chat.model.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatController _chatController = ChatController();
  List<ChatModel> _chats = [];
  bool _isLoading = true;

  Timer? _debounce;

  List<ChatModel> _searchUsers = [];
  bool _isSearching = false;

  final TextEditingController _searchController = TextEditingController();

  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadChats();
    _searchController.addListener(() {
      setState(() {});
    });
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
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
    final list = _isSearching ? _searchUsers : _chats;
    final auth = Get.find<AuthController>();
    final viewerRole = auth.roleName.value?.toLowerCase();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,

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
        actions: [
  if (viewerRole == "high school student" || viewerRole == "uni student")
    Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        // decoration: BoxDecoration(
        //   color: AppColors.primaryPalette[100],
        //   shape: BoxShape.circle,
        // ),
        child: IconButton(
          icon: Icon(
            Icons.auto_awesome,
            color: AppColors.primaryPalette[600],
            size: 22,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AIChatListPage(),
              ),
            );
          },
        ),
      ),
    ),
],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _buildSearch(),
          const SizedBox(height: 10),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (context, index) {
                            if (_isSearching) {
                              return Divider(
                                height: 1,
                                thickness: 1,
                                color: AppColors.buttonPalette[200]!.withValues(
                                  alpha: 0.4,
                                ),
                                indent: 16,
                                endIndent: 16,
                              );
                            }

                            return const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFF0F0F0),
                              indent: 16,
                              endIndent: 16,
                            );
                          },
                          itemBuilder: (context, index) {
                            final chat = list[index];

                            if (_isSearching) {
                              return _buildSearchUserItem(chat);
                            }

                            return _buildChatItem(chat);
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 45,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(30)),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            onChanged: (value) {
              _onSearchChanged(value);
            },
            decoration: InputDecoration(
              hintText: "ค้นหาผู้ใช้...",
              hintStyle: const TextStyle(
                fontSize: 14,
                color: Color(0xFF9E9E9E),
              ),

              prefixIcon: Icon(
                Icons.search,
                color: AppColors.buttonPalette[600],
                size: 22,
              ),

              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: AppColors.buttonPalette[600],
                      onPressed: () {
                        _resetSearch();
                        _loadChats();
                      },
                    )
                  : null,

              filled: true,
              fillColor: AppColors.buttonPalette[100]!.withValues(alpha: 0.2),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(
                  color: AppColors.buttonPalette[300]!,
                  width: 1.2,
                ),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(
                  color: AppColors.buttonPalette[300]!,
                  width: 1.2,
                ),
              ),

              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build individual chat item
  Widget _buildChatItem(ChatModel chat) {
    return InkWell(
      onTap: () async {
        if (_isSearching) {
          final senderId = await LocalStorage.getLastLoginUserId();

          final newChat = await _chatController.createChat(
            isAiChat: false,
            senderId: senderId!,
            receiverId: chat.userSysId!,
          );

          final mergedChat = ChatModel(
            chatId: newChat.chatId,
            senderId: newChat.senderId,
            receiverId: newChat.receiverId,
            userSysId: chat.userSysId,
            firstName: chat.firstName,
            lastName: chat.lastName,
            profileImage: chat.profileImage,
          );

          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatMessagePage(chat: chat)),
          );

          _resetSearch();

          await _loadChats();
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatMessagePage(chat: chat)),
          );

          await _loadChats();
        }
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
                    backgroundImage:
                        chat.profileImage != null &&
                            chat.profileImage!.isNotEmpty
                        ? NetworkImage(chat.profileImage!)
                        : null,
                    child:
                        chat.profileImage == null || chat.profileImage!.isEmpty
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
                          '${chat.firstName ?? ''} ${chat.lastName ?? ''}'
                              .trim(),
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
                          _previewMessage(chat),
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

  Widget _buildSearchUserItem(ChatModel user) {
    return InkWell(
      onTap: () async {
        final senderId = await LocalStorage.getLastLoginUserId();

        final newChat = await _chatController.createChat(
          isAiChat: false,
          senderId: senderId!,
          receiverId: user.userSysId!,
        );

        final mergedChat = ChatModel(
          chatId: newChat.chatId,
          senderId: newChat.senderId,
          receiverId: newChat.receiverId,
          userSysId: user.userSysId,
          firstName: user.firstName,
          lastName: user.lastName,
          profileImage: user.profileImage,
        );

        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatMessagePage(chat: mergedChat)),
        );
        _resetSearch();

        await _loadChats();
      },
      child: Container(
        margin: _isSearching
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
            : EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isSearching
              ? AppColors.buttonPalette[100]!.withValues(alpha: 0.35)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage:
                  user.profileImage != null && user.profileImage!.isNotEmpty
                  ? NetworkImage(user.profileImage!)
                  : null,
              backgroundColor: _getAvatarColor(user.firstName ?? ''),
              child: user.profileImage == null || user.profileImage!.isEmpty
                  ? Text(
                      _getInitials(user.firstName, user.lastName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "${user.firstName ?? ""} ${user.lastName ?? ""}",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
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

  void _onSearchChanged(String keyword) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchUsersApi(keyword);
    });
  }

  Future<void> _searchUsersApi(String keyword) async {
    if (keyword.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchUsers.clear();
      });

      _loadChats();
      return;
    }

    final users = await _chatController.searchUsers(keyword);

    setState(() {
      _isSearching = true;
      _searchUsers = users;
    });
  }

  String _previewMessage(ChatModel chat) {
    if (chat.lastMessage == "[image]") {
      return "ส่งรูปภาพ";
    }

    if (chat.lastMessage == "[file]") {
      return " ส่งไฟล์";
    }

    if (chat.lastMessage != null && chat.lastMessage!.startsWith("http")) {
      return "ส่งลิงก์";
    }

    return chat.lastMessage ?? "";
  }

  void _resetSearch() {
    _searchFocus.unfocus();

    setState(() {
      _searchController.clear();
      _searchUsers.clear();
      _isSearching = false;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }
}
