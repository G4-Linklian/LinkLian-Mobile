import 'dart:async';
import 'package:LinkLian/core/services/local_storage.dart';
import 'package:LinkLian/core/services/socket_service.dart';
import 'package:LinkLian/data/model/chat.model.dart';
import 'package:LinkLian/data/repository/chat.repository.dart';
import 'package:LinkLian/core/utils/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatMessageController {
  final SocketService _socketService = SocketService();
  final ChatRepository _chatRepository = ChatRepository();
  final StreamController<List<ChatModel>> _messagesController = StreamController<List<ChatModel>>.broadcast();
  Stream<List<ChatModel>> get messagesStream => _messagesController.stream;

  List<ChatModel> _messages = [];
  int? _currentUserId;
  int? get currentUserId => _currentUserId;
  int? _currentChatId;
  
  // Debounce timer for UI updates
  Timer? _updateTimer;
  bool _hasUpdates = false;

  Future<void> init(int chatId) async {
    _currentChatId = chatId;
    _currentUserId = await LocalStorage.getLastLoginUserId();

    if (_currentUserId == null) {
      AppLogger.error('User ID not found');
      return;
    }

    // Load messages from API
    await _loadMessages();

    // Socket functionality
    await _socketService.connect(dotenv.env['SOCKET_URL'] ?? 'wss://socket-wachawich.linklian.org/ws');
    _socketService.joinRoom(userId: _currentUserId!, chatId: chatId);
    _socketService.socketResponseStream.listen((data) {
      _handleIncomingMessage(data);
    });
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _chatRepository.getMessage(
        chatId: _currentChatId,
        sortBy: 'created_at',
        sortOrder: 'asc',
      );
      
      _messages = messages;
      // Direct update for initial load (no debounce needed)
      _messagesController.add(List.unmodifiable(_messages));
      AppLogger.info('Loaded ${messages.length} messages for chat $_currentChatId');
    } catch (e) {
      AppLogger.error('Failed to load messages: $e');
    }
  }

  void _handleIncomingMessage(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        if (data['type'] == 'CHAT_RECEIVE' || data['content'] != null) {
          final payload = data['payload'] ?? data;
          final newMessage = ChatModel.fromJson(payload);
          _messages.add(newMessage);
          _scheduleUIUpdate();
        }
      }
    } catch (e) {
      AppLogger.error('Error parsing chat message: $e');
    }
  }
  
  void _scheduleUIUpdate() {
    _hasUpdates = true;
    _updateTimer?.cancel();
    _updateTimer = Timer(const Duration(milliseconds: 50), () {
      if (_hasUpdates && !_messagesController.isClosed) {
        _messagesController.add(List.unmodifiable(_messages));
        _hasUpdates = false;
      }
    });
  }

  Future<void> sendMessage(String content) async {
    if (_currentUserId == null || _currentChatId == null) return;

    try {
      final newMessage = await _chatRepository.createMessage(
        chatId: _currentChatId!,
        senderId: _currentUserId!,
        content: content,
      );

      // Add the new message to local list
      _messages.add(newMessage);
      // Use direct update for user messages (immediate feedback)
      _messagesController.add(List.unmodifiable(_messages));
      
      AppLogger.info('Message sent successfully');
    } catch (e) {
      AppLogger.error('Failed to send message: $e');
    }

    // Socket functionality
    final message = {
      'type': 'SEND_MESSAGE',
      'payload': {
        'chat_id': _currentChatId,
        'user_id': _currentUserId,
        'content': content,
      }
    };
    _socketService.sendMessage(message);
  }

  void dispose() {
    _updateTimer?.cancel();
    _socketService.disconnect();
    _messagesController.close();
  }
}
