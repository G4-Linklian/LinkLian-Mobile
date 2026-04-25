import 'dart:async';
import 'dart:io';
import 'package:LinkLian/core/services/local_storage.dart';
import 'package:LinkLian/core/services/socket_service.dart';
import 'package:LinkLian/features/chat/data/models/chat.model.dart';
import 'package:LinkLian/features/chat/data/repository/chat.repository.dart';
import 'package:LinkLian/core/utils/logger.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';

class ChatMessageController {
  final SocketService _socketService = SocketService();
  final ChatRepository _chatRepository = ChatRepository();
  ChatModel? replyingMessage;
  final StreamController<List<ChatModel>> _messagesController =
      StreamController<List<ChatModel>>.broadcast();
  Stream<List<ChatModel>> get messagesStream => _messagesController.stream;

  List<ChatModel> _messages = [];
  List<ChatModel> get messages => _messages;
  int? _currentUserId;
  int? get currentUserId => _currentUserId;
  int? _currentChatId;

  // Debounce timer for UI updates
  Timer? _updateTimer;
  bool _hasUpdates = false;
  StreamSubscription? _socketSubscription;
  final Set<String> _socketFallbackKeys = <String>{};

  Future<void> init(int chatId) async {
    // BUG FIX #2: Validate chatId
    if (chatId <= 0) {
      appLog.error('Invalid chatId: $chatId');
      return;
    }

    _currentChatId = chatId;
    _currentUserId = await LocalStorage.getLastLoginUserId();

    if (_currentUserId == null) {
      appLog.error('User ID not found');
      return;
    }

    // Load messages from API
    await _loadMessages();

    // Socket functionality
    final socketUrl =
        '${dotenv.env['SOCKET_URL'] ?? 'wss://socket-wachawich.linklian.org/ws'}/chat';
    if (!_socketService.isConnected) {
      await _socketService.connect(socketUrl);
    }
    _socketService.joinRoom(userId: _currentUserId!, chatId: chatId);
    // _socketService.socketResponseStream.listen((data) {
    //    print("WS DATA: $data");
    //   _handleIncomingMessage(data);
    // });
    _socketSubscription?.cancel();

    _socketSubscription = _socketService.socketResponseStream.listen((data) {
      _handleIncomingMessage(data);
    });
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _chatRepository.getMessage(
        chatId: _currentChatId,
        sortBy: 'created_at',
        sortOrder: 'asc',
        fromReadChat: true,
        viewerId: _currentUserId,
      );

      _messages = messages;
      _socketFallbackKeys.clear();
      // Direct update for initial load (no debounce needed)
      _messagesController.add(List.unmodifiable(_messages));
      appLog.info(
        'Loaded ${messages.length} messages for chat $_currentChatId',
      );
    } catch (e) {
      appLog.error('Failed to load messages: $e');
    }
  }

  void _handleIncomingMessage(dynamic data) {
    try {
      if (data is! Map<String, dynamic>) return;

      final eventType = (data['type'] ?? '').toString();
      if (eventType != 'CHAT_RECEIVE' && eventType != 'CHAT_DELIVER') return;

      final payload = data['payload'] ?? data['data'] ?? data;
      if (payload is! Map<String, dynamic>) return;

      final newMessage = ChatModel.fromJson(payload);

      // Ignore messages from other rooms when chat_id is present.
      if (_currentChatId != null &&
          newMessage.chatId != null &&
          newMessage.chatId != _currentChatId) {
        return;
      }

      final fallbackKey = _buildFallbackSocketKey(payload);

      final exists = _messages.any((m) {
        // Primary dedupe: stable message_id from backend.
        if (newMessage.messageId != null && m.messageId != null) {
          return m.messageId == newMessage.messageId;
        }

        // Fallback dedupe for payloads that come with empty message_id.
        return m.chatId == newMessage.chatId &&
            m.senderId == newMessage.senderId &&
            m.content == newMessage.content &&
            m.createdAt == newMessage.createdAt;
      });

      final seenByFallbackKey =
          newMessage.messageId == null &&
          _socketFallbackKeys.contains(fallbackKey);

      if (!exists && !seenByFallbackKey) {
        _messages.add(newMessage);
        if (newMessage.messageId == null) {
          _socketFallbackKeys.add(fallbackKey);
        }
        appLog.info(
          'Realtime message added: chat=${newMessage.chatId} sender=${newMessage.senderId} id=${newMessage.messageId}',
        );
        _scheduleUIUpdate();
      } else {
        appLog.info(
          'Realtime message skipped as duplicate: chat=${newMessage.chatId} sender=${newMessage.senderId} id=${newMessage.messageId}',
        );
      }
    } catch (e) {
      appLog.error('Error parsing chat message: $e');
    }
  }

  String _buildFallbackSocketKey(Map<String, dynamic> payload) {
    final chatId = (payload['chat_id'] ?? '').toString();
    final senderId = (payload['sender_id'] ?? '').toString();
    final content = (payload['content'] ?? '').toString();
    final createdAt = (payload['created_at'] ?? payload['send_at'] ?? '')
        .toString();

    return '$chatId|$senderId|$content|$createdAt';
  }

  void _scheduleUIUpdate() {
    _hasUpdates = true;
    _updateTimer?.cancel();
    _updateTimer = Timer(const Duration(milliseconds: 120), () {
      if (_hasUpdates && !_messagesController.isClosed) {
        _messagesController.add(List.unmodifiable(_messages));
        _hasUpdates = false;
      }
    });
  }

  Future<void> sendMessage(String content) async {
    // BUG FIX #3 & #7: Validate content and notify user of failure
    if (content.trim().isEmpty) {
      appLog.error('Cannot send empty message');
      return;
    }

    if (_currentUserId == null || _currentChatId == null) {
      appLog.error('Cannot send message: userId or chatId is null');
      return;
    }

    try {
      final newMessage = await _chatRepository.createMessage(
        chatId: _currentChatId!,
        senderId: _currentUserId!,
        content: content,
        replyId: replyingMessage?.messageId,
      );
      replyingMessage = null;
      // Add the new message to local list
      _messages.add(newMessage);
      // Use direct update for user messages (immediate feedback)
      // _messagesController.add(List.unmodifiable(_messages));
      _scheduleUIUpdate();
      appLog.info('Message sent successfully');
    } catch (e) {
      appLog.error('Failed to send message: $e');
    }

    // Socket functionality
    final message = {
      'type': 'SEND_MESSAGE',
      'payload': {
        'chat_id': _currentChatId,
        'user_id': _currentUserId,
        'content': content,
      },
    };
    _socketService.sendMessage(message);
  }

  void dispose() {
    // BUG FIX #4: Clear all state on dispose
    _updateTimer?.cancel();
    _socketSubscription?.cancel();
    _socketService.disconnect();
    _messages.clear();
    _currentUserId = null;
    _currentChatId = null;
    replyingMessage = null;
    _socketFallbackKeys.clear();
    _messagesController.close();
  }

  Future<void> pickImage(ImageSource source) async {
    // Validate state
    if (_currentUserId == null || _currentChatId == null) {
      appLog.error('Cannot pick image: userId or chatId is null');
      return;
    }

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source);

      if (picked == null) return;

      final file = File(picked.path);

      final newMessage = await _chatRepository.createMessage(
        chatId: _currentChatId!,
        senderId: _currentUserId!,
        content: "[image]",
        file: [file],
      );

      _messages.add(newMessage);
      // _messagesController.add(List.unmodifiable(_messages));
      _scheduleUIUpdate();
    } catch (e) {
      appLog.error('Failed to pick image: $e');
    }
  }

  Future<void> pickFile() async {
    // Validate state
    if (_currentUserId == null || _currentChatId == null) {
      appLog.error('Cannot pick file: userId or chatId is null');
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles();

      if (result == null) return;

      final file = File(result.files.single.path!);

      final newMessage = await _chatRepository.createMessage(
        chatId: _currentChatId!,
        senderId: _currentUserId!,
        content: "[file]",
        file: [file],
      );

      _messages.add(newMessage);
      // _messagesController.add(List.unmodifiable(_messages));
      _scheduleUIUpdate();
    } catch (e) {
      appLog.error('Failed to pick file: $e');
    }
  }

  Future<void> sendLink(String url) async {
    // Validate URL and state
    if (url.trim().isEmpty) {
      appLog.error('Cannot send empty URL');
      return;
    }

    if (_currentUserId == null || _currentChatId == null) {
      appLog.error('Cannot send link: userId or chatId is null');
      return;
    }

    try {
      final newMessage = await _chatRepository.createMessage(
        chatId: _currentChatId!,
        senderId: _currentUserId!,
        content: url,
      );

      _messages.add(newMessage);
      // _messagesController.add(List.unmodifiable(_messages));
      _scheduleUIUpdate();
    } catch (e) {
      appLog.error("send link error: $e");
    }
  }

  ChatModel? findReplyMessage(int? replyId) {
    if (replyId == null) return null;

    try {
      return _messages.firstWhere((m) => m.messageId == replyId);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadMessageById(int messageId) async {
    try {
      final result = await _chatRepository.getMessage(messageId: messageId);

      if (result.isEmpty) return;

      final message = result.first;

      final exists = _messages.any((m) => m.messageId == message.messageId);

      if (!exists) {
        _messages.insert(0, message);
        _scheduleUIUpdate();
      }
    } catch (e) {
      appLog.error("loadMessageById error: $e");
    }
  }
}
