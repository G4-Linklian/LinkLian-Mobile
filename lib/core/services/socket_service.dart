import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:LinkLian/core/utils/logger.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  WebSocketChannel? _channel;
  final StreamController<dynamic> _socketResponseController = StreamController<dynamic>.broadcast();
  Stream<dynamic> get socketResponseStream => _socketResponseController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Future<void> connect(String url) async {
    if (_isConnected) {
      AppLogger.info('Socket is already connected.');
      return;
    }

    try {
      AppLogger.info('Connecting to WebSocket: $url');
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;

      _channel!.stream.listen(
        (message) {
          AppLogger.info('WS Received: $message');
          // Use async parsing to avoid blocking main thread
          _parseMessageAsync(message);
        },
        onError: (error) {
          AppLogger.error('WS Error: $error');
          _isConnected = false;
        },
        onDone: () {
          AppLogger.info('WS Disconnected');
          _isConnected = false;
        },
      );
    } catch (e) {
      AppLogger.error('WS Connection Exception: $e');
      _isConnected = false;
    }
  }

  void joinRoom({required int userId, required int chatId}) {
    if (!_isConnected || _channel == null) {
      AppLogger.warning('Socket not connected. Cannot join room.');
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
      AppLogger.info('WS Sending: $jsonMessage');
      _channel!.sink.add(jsonMessage);
    } else {
      AppLogger.warning('Socket not connected. Cannot send message.');
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
          AppLogger.error('Error decoding WS message: $e');
          // If it's not JSON, pass it as is or handle accordingly
          if (!_socketResponseController.isClosed) {
            _socketResponseController.add(message);
          }
        }
      });
    } catch (e) {
      AppLogger.error('Error in async message parsing: $e');
    }
  }

  void disconnect() {
    if (_isConnected) {
      _channel?.sink.close();
      _isConnected = false;
      AppLogger.info('Socket manual disconnect');
    }
  }

  void dispose() {
    disconnect();
    _socketResponseController.close();
  }
}
