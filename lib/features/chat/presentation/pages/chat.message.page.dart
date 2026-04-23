import 'dart:math' as math;
import 'package:LinkLian/core/constants/colors.dart';
import 'package:LinkLian/core/constants/linklian-icon.dart';
import 'package:LinkLian/core/utils/online_presence_utils.dart';
import 'package:flutter/material.dart';
import 'package:LinkLian/features/chat/data/models/chat.model.dart';
import 'package:LinkLian/features/chat/presentation/controllers/chat.message.controller.dart';
import 'package:LinkLian/features/chat/presentation/widgets/chat.message.widget.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ChatMessagePage extends StatefulWidget {
  final ChatModel chat;

  const ChatMessagePage({super.key, required this.chat});

  @override
  State<ChatMessagePage> createState() => _ChatMessagePageState();
}

class _ChatMessagePageState extends State<ChatMessagePage> {
  final ChatMessageController _controller = ChatMessageController();
  final TextEditingController _textController = TextEditingController();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  int? _highlightMessageId;
  int? _jumpBackIndex;
  bool _showScrollToLatestButton = false;
  bool _suppressScrollToLatestButton = true;
  bool _initialScrollDone = false;
  DateTime? _jumpBackReadyTime;
  int _lastRenderedMessageCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.chat.chatId != null) {
      _controller.init(widget.chat.chatId!);
    }
    // Hide go-back button
    _itemPositionsListener.itemPositions.addListener(_onPositionsChanged);
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onPositionsChanged);
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onPositionsChanged() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    if (_suppressScrollToLatestButton) {
      if (_showScrollToLatestButton) {
        setState(() {
          _showScrollToLatestButton = false;
        });
      }
      return;
    }

    final latestIndex = _controller.messages.length - 1;
    if (latestIndex >= 0) {
      final maxVisibleIndex = positions.map((p) => p.index).reduce(math.max);
      final shouldShowLatestButton = (latestIndex - maxVisibleIndex) > 3;
      if (shouldShowLatestButton != _showScrollToLatestButton) {
        setState(() {
          _showScrollToLatestButton = shouldShowLatestButton;
        });
      }
    }

    if (_jumpBackIndex == null) return;
    if (_jumpBackReadyTime != null &&
        DateTime.now().isBefore(_jumpBackReadyTime!)) {
      return;
    }

    final closestVisible = positions.reduce(
      (a, b) =>
          (a.index - _jumpBackIndex!).abs() < (b.index - _jumpBackIndex!).abs()
          ? a
          : b,
    );
    if ((closestVisible.index - _jumpBackIndex!).abs() <= 3) {
      setState(() {
        _jumpBackIndex = null;
      });
    }
  }

  // void _handleSend() async {
  //   final text = _textController.text.trim();
  //   if (text.isNotEmpty) {
  //     _textController.clear();
  //     await _controller.sendMessage(text);
  //     setState(() {});
  //     _scrollToBottom();
  //   }
  // }
  void _handleSend() async {
    final text = _textController.text.trim();

    final displayName =
        "${widget.chat.firstName ?? ''} ${widget.chat.lastName ?? ''}".trim();

    final isDeletedUser = displayName.isEmpty;

    if (isDeletedUser) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("ไม่สามารถส่งข้อความได้")));
      return;
    }

    if (text.isNotEmpty) {
      _textController.clear();
      await _controller.sendMessage(text);
      setState(() {});
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_itemScrollController.isAttached && _controller.messages.isNotEmpty) {
        _itemScrollController.scrollTo(
          index: _controller.messages.length - 1,
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
        );
        if (_showScrollToLatestButton) {
          setState(() {
            _showScrollToLatestButton = false;
          });
        }
      }
    });
  }

  Future<void> _scrollToMessage(int messageId, {int? fromIndex}) async {
    if (!_controller.messages.any((m) => m.messageId == messageId)) {
      await _controller.loadMessageById(messageId);
    }

    final index = _controller.messages.indexWhere(
      (m) => m.messageId == messageId,
    );
    if (index == -1) return;

    // Save the index of the message user tapped from, so they can jump back
    // Delay position check so scroll animation doesn't immediately dismiss the button
    _jumpBackReadyTime = DateTime.now().add(const Duration(seconds: 2));
    if (fromIndex != null) {
      setState(() {
        _jumpBackIndex = fromIndex;
      });
    } else {
      final positions = _itemPositionsListener.itemPositions.value;
      if (positions.isNotEmpty) {
        final sorted = positions.toList()
          ..sort((a, b) => a.index.compareTo(b.index));
        setState(() {
          _jumpBackIndex = sorted.last.index;
        });
      }
    }

    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 620),
        curve: Curves.easeInOutCubic,
        alignment: 0.18,
      );
    }

    await Future.delayed(const Duration(milliseconds: 200));

    setState(() {
      _highlightMessageId = messageId;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _highlightMessageId = null;
        });
      }
    });
  }

  void _jumpBack() {
    if (_jumpBackIndex == null || !_itemScrollController.isAttached) return;
    final backIndex = _jumpBackIndex!;
    _itemScrollController.scrollTo(
      index: backIndex,
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeInOutCubic,
      alignment: 0.18,
    );

    // Highlight the message we jumped back to
    final messages = _controller.messages;
    final targetMessageId = (backIndex >= 0 && backIndex < messages.length)
        ? messages[backIndex].messageId
        : null;

    setState(() {
      _jumpBackIndex = null;
      _highlightMessageId = targetMessageId;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _highlightMessageId = null;
        });
      }
    });
  }

  bool _isUserNearBottom(int lastKnownIndex, {int tolerance = 1}) {
    if (lastKnownIndex <= 0) return true;

    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return true;

    final maxVisibleIndex = positions.map((p) => p.index).reduce(math.max);

    return maxVisibleIndex >= (lastKnownIndex - tolerance);
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        "${widget.chat.firstName ?? ''} ${widget.chat.lastName ?? ''}".trim();

    final isDeletedUser = displayName.isEmpty;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            ValueListenableBuilder<Map<int, bool>>(
              valueListenable: OnlinePresenceUtils.onlineStatuses,
              builder: (_, statuses, __) {
                final userId = widget.chat.userSysId;
                final isOnline =
                    !isDeletedUser && userId != null && (statuses[userId] ?? false);

                final baseAvatar = Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE0E0E0),
                      width: 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: isDeletedUser
                        ? Colors.grey[300]
                        : (widget.chat.profileImage == null ||
                              widget.chat.profileImage!.isEmpty)
                        ? _getAvatarColor(widget.chat.firstName ?? '')
                        : Colors.transparent,
                    backgroundImage:
                        !isDeletedUser &&
                            widget.chat.profileImage != null &&
                            widget.chat.profileImage!.isNotEmpty
                        ? NetworkImage(widget.chat.profileImage!)
                        : null,
                    child: isDeletedUser
                        ? Icon(
                            LinkLianIcon.useroff,
                            color: Colors.grey[600],
                            size: 20,
                          )
                        : (widget.chat.profileImage == null ||
                                  widget.chat.profileImage!.isEmpty
                              ? Text(
                                  _getInitials(
                                    widget.chat.firstName,
                                    widget.chat.lastName,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : null),
                  ),
                );

                if (!isOnline) {
                  return baseAvatar;
                }

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    baseAvatar,
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName.isNotEmpty
                        ? displayName
                        : "ไม่มีบัญชีผู้ใช้งาน",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                StreamBuilder<List<ChatModel>>(
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
                    final hasNewMessages =
                        messages.length > _lastRenderedMessageCount;
                    final wasNearBottom = _isUserNearBottom(
                      _lastRenderedMessageCount - 1,
                    );

                    // Auto scroll to bottom only on first load
                    if (messages.isNotEmpty && !_initialScrollDone) {
                      _initialScrollDone = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                        Future.delayed(const Duration(milliseconds: 450), () {
                          if (!mounted || !_suppressScrollToLatestButton) {
                            return;
                          }
                          setState(() {
                            _suppressScrollToLatestButton = false;
                          });
                        });
                      });
                    } else if (hasNewMessages && wasNearBottom) {
                      // Keep view pinned to newest messages only when user
                      // was already reading from the bottom.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });
                    }

                    _lastRenderedMessageCount = messages.length;

                    // Debounce auto scroll to prevent excessive scrolling
                    return ScrollablePositionedList.builder(
                      itemScrollController: _itemScrollController,
                      itemPositionsListener: _itemPositionsListener,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe =
                            message.senderId == _controller.currentUserId;
                        final replyMessage = _controller.findReplyMessage(
                          message.replyId,
                        );
                        final isReplyDeletedUser =
                            replyMessage != null &&
                            ((replyMessage.firstName == null ||
                                    replyMessage.firstName!.isEmpty) &&
                                (replyMessage.lastName == null ||
                                    replyMessage.lastName!.isEmpty));
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
                          key: ValueKey(
                            'message_${message.messageId ?? index}',
                          ),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showDateSeparator)
                              ChatDateSeparator(
                                key: ValueKey(
                                  'date_${message.createdAt?.day}_${message.createdAt?.month}',
                                ),
                                date: message.createdAt ?? DateTime.now(),
                              ),
                            ChatMessageBubble(
                              key: ValueKey(
                                'bubble_${message.messageId ?? index}',
                              ),
                              message: message,
                              replyMessage: replyMessage,
                              isMe: isMe,
                              currentUserId: _controller.currentUserId,
                              senderFirstName: widget.chat.firstName,
                              senderLastName: widget.chat.lastName,
                              profileImage: widget.chat.profileImage,
                              highlight:
                                  _highlightMessageId != null &&
                                  message.messageId == _highlightMessageId,

                              isReplyDeletedUser: isReplyDeletedUser,
                              onReply: (msg) {
                                setState(() {
                                  _controller.replyingMessage = msg;
                                });
                              },
                              onJumpToMessage: (messageId) {
                                _scrollToMessage(messageId, fromIndex: index);
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                if (_jumpBackIndex != null || _showScrollToLatestButton)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (_jumpBackIndex != null)
                          Material(
                            elevation: 4,
                            color: AppColors.primaryPalette[500],
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _jumpBack,
                              child: const Padding(
                                padding: EdgeInsets.all(9),
                                child: Icon(
                                  Icons.arrow_downward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        if (_jumpBackIndex != null && _showScrollToLatestButton)
                          const SizedBox(height: 10),
                        if (_showScrollToLatestButton)
                          Material(
                            elevation: 4,
                            color: AppColors.primaryPalette[500],
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _scrollToBottom,
                              child: const Padding(
                                padding: EdgeInsets.all(9),
                                child: Icon(
                                  Icons.arrow_downward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// REPLY PREVIEW BAR
              if (_controller.replyingMessage != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.primaryPalette[500]!.withValues(
                          alpha: 0.5,
                        ),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.reply_rounded,
                        size: 18,
                        color: AppColors.primaryPalette[600],
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _controller.replyingMessage?.senderId ==
                                      _controller.currentUserId
                                  ? "ตอบกลับคุณ"
                                  : "ตอบกลับข้อความ",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryPalette[700],
                              ),
                            ),
                            Text(
                              _controller.replyingMessage!.content ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),

                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _controller.replyingMessage = null;
                          });
                        },
                        child: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                ),
              ChatInputArea(
                textController: _textController,
                isDeletedUser: isDeletedUser,

                ///onSend: isDeletedUser ? null : _handleSend,
                onSend: () {
                  if (!isDeletedUser) {
                    _handleSend();
                  }
                },
                controller: _controller,
              ),
            ],
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
