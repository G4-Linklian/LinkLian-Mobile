import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:LinkLian/core/utils/logger.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  // ─── Chat channel ────────────────────────────────────────────────────────────
  WebSocketChannel? _channel;
  final StreamController<dynamic> _socketResponseController = StreamController<dynamic>.broadcast();
  Stream<dynamic> get socketResponseStream => _socketResponseController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // ─── Notification channel ────────────────────────────────────────────────────
  WebSocketChannel? _notiChannel;
  StreamSubscription? _notiSub;
  final StreamController<dynamic> _notiController = StreamController<dynamic>.broadcast();
  Stream<dynamic> get notiStream => _notiController.stream;

  bool _notiConnected = false;
  int? _notiUserId;

  Future<void> connectNotification(int userId) async {
    if (_notiConnected && _notiUserId == userId) return;
    if (_notiConnected) await disconnectNotification();

    final base = dotenv.env['SOCKET_URL'] ?? 'wss://socket-wachawich.linklian.org/ws';
    final url = '$base/notification';

    try {
      appLog.info('NotificationSocket: connecting to $url');
      _notiChannel = WebSocketChannel.connect(Uri.parse(url));
      _notiConnected = true;
      _notiUserId = userId;

      _notiSub = _notiChannel!.stream.listen(
        (message) {
          Future.microtask(() {
            try {
              final decoded = jsonDecode(message as String);
              if (!_notiController.isClosed) _notiController.add(decoded);
            } catch (_) {
              if (!_notiController.isClosed) _notiController.add(message);
            }
          });
        },
        onError: (e) {
          appLog.error('NotificationSocket error: $e');
          _notiConnected = false;
        },
        onDone: () {
          appLog.info('NotificationSocket disconnected');
          _notiConnected = false;
        },
      );

      _notiChannel!.sink.add(jsonEncode({
        'type': 'REGISTER_NOTI',
        'payload': {'user_id': userId.toString()},
      }));
      appLog.info('NotificationSocket: REGISTER_NOTI sent for userId=$userId');
    } catch (e) {
      appLog.error('NotificationSocket connect error: $e');
      _notiConnected = false;
    }
  }

  Future<void> disconnectNotification() async {
    await _notiSub?.cancel();
    _notiSub = null;
    await _notiChannel?.sink.close(WebSocketStatus.normalClosure);
    _notiChannel = null;
    _notiConnected = false;
    _notiUserId = null;
    appLog.info('NotificationSocket: disconnected');
  }

  Future<void> connect(String url) async {
    if (_isConnected) {
      appLog.info('Socket is already connected.');
      return;
    }

    try {
      appLog.info('Connecting to WebSocket: $url');
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;

      _channel!.stream.listen(
        (message) {
          appLog.info('WS Received: $message');
          // Use async parsing to avoid blocking main thread
          _parseMessageAsync(message);
        },
        onError: (error) {
          appLog.error('WS Error: $error');
          _isConnected = false;
        },
        onDone: () {
          appLog.info('WS Disconnected');
          _isConnected = false;
        },
      );
    } catch (e) {
      appLog.error('WS Connection Exception: $e');
      _isConnected = false;
    }
  }

  void joinRoom({required int userId, required int chatId}) {
    if (!_isConnected || _channel == null) {
      appLog.warning('Socket not connected. Cannot join room.');
      return;
    }

    final message = {
      'type': 'JOIN_ROOM',
      'payload': {
        'user_id': userId.toString(),
        'chat_id': chatId.toString(),
      }
    };

    sendMessage(message);
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      final jsonMessage = jsonEncode(message);
      appLog.info('WS Sending: $jsonMessage');
      _channel!.sink.add(jsonMessage);
    } else {
      appLog.warning('Socket not connected. Cannot send message.');
    }
  }

  // Parse JSON message asynchronously to avoid blocking main thread
  Future<void> _parseMessageAsync(String message) async {
    try {
      // Schedule JSON parsing on next frame to avoid blocking current frame
      Future.microtask(() {
        try {
          final decoded = jsonDecode(message);
          if (!_socketResponseController.isClosed) {
            _socketResponseController.add(decoded);
          }
        } catch (e) {
          appLog.error('Error decoding WS message: $e');
          // If it's not JSON, pass it as is or handle accordingly
          if (!_socketResponseController.isClosed) {
            _socketResponseController.add(message);
          }
        }
      });
    } catch (e) {
      appLog.error('Error in async message parsing: $e');
    }
  }

  void disconnect() {
    if (_isConnected) {
      _channel?.sink.close(WebSocketStatus.normalClosure);
      _isConnected = false;
      appLog.info('Socket manual disconnect');
    }
  }

  void dispose() {
    disconnect();
    _socketResponseController.close();
  }
}
