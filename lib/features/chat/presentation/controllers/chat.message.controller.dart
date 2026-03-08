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

  Future<void> init(int chatId) async {
    _currentChatId = chatId;
    _currentUserId = await LocalStorage.getLastLoginUserId();

    if (_currentUserId == null) {
      appLog.error('User ID not found');
      return;
    }

    // Load messages from API
    await _loadMessages();

    // Socket functionality
    // await _socketService.connect(
    //   dotenv.env['SOCKET_URL'] ?? 'wss://socket-wachawich.linklian.org/ws',
    // );
    final socketUrl =
        dotenv.env['SOCKET_URL'] ?? 'wss://socket-wachawich.linklian.org/ws';
    print("SOCKET URL = ${dotenv.env['SOCKET_URL']}");
    if (!_socketService.isConnected) {
      print("CONNECT SOCKET");
      await _socketService.connect(socketUrl);
    }
    print("JOIN ROOM user=$_currentUserId chat=$chatId");
    _socketService.joinRoom(userId: _currentUserId!, chatId: chatId);
    // _socketService.socketResponseStream.listen((data) {
    //    print("WS DATA: $data");
    //   _handleIncomingMessage(data);
    // });
    _socketSubscription?.cancel();

    _socketSubscription = _socketService.socketResponseStream.listen((data) {
      print("WS DATA: $data");
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
      appLog.info(
        'Loaded ${messages.length} messages for chat $_currentChatId',
      );
    } catch (e) {
      appLog.error('Failed to load messages: $e');
    }
  }

  void _handleIncomingMessage(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        //if (data['type'] == 'CHAT_RECEIVE' || data['content'] != null) {
        //if (data['type'] == 'CHAT_RECEIVE' || data['content'] != null) {
        if (data['type'] == 'CHAT_RECEIVE' || data['type'] == 'CHAT_DELIVER') {
          final payload = data['payload'] ?? data['data'] ?? data;
          // final payload = data['payload'] ?? data;
          // final newMessage = ChatModel.fromJson(paylo
          // ad);
          // _messages.add(newMessage);
          // _scheduleUIUpdate();
          final newMessage = ChatModel.fromJson(payload);

          final exists = _messages.any(
            (m) => m.messageId == newMessage.messageId,
          );

          if (!exists) {
            _messages.add(newMessage);
            _scheduleUIUpdate();
          }
        }
      }
    } catch (e) {
      appLog.error('Error parsing chat message: $e');
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
    _updateTimer?.cancel();
    _socketSubscription?.cancel();
    // _socketService.disconnect();
    _messagesController.close();
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);

    if (picked == null) return;

    final file = File(picked.path);

    final newMessage = await _chatRepository.createMessage(
      chatId: _currentChatId!,
      senderId: _currentUserId!,
      content: "[image]",
      file: file,
    );

    _messages.add(newMessage);
    // _messagesController.add(List.unmodifiable(_messages));
    _scheduleUIUpdate();
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result == null) return;

    final file = File(result.files.single.path!);

    final newMessage = await _chatRepository.createMessage(
      chatId: _currentChatId!,
      senderId: _currentUserId!,
      content: "[file]",
      file: file,
    );

    _messages.add(newMessage);
    // _messagesController.add(List.unmodifiable(_messages));
    _scheduleUIUpdate();
  }

  Future<void> sendLink(String url) async {
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
