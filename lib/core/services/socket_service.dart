import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:LinkLian/core/utils/logger.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  WebSocketChannel? _channel;
  WebSocketChannel? _onlineChannel;
  final StreamController<dynamic> _socketResponseController =
      StreamController<dynamic>.broadcast();
    final StreamController<dynamic> _onlineStreamController =
      StreamController<dynamic>.broadcast();
  Stream<dynamic> get socketResponseStream => _socketResponseController.stream;
    Stream<dynamic> get onlineStream => _onlineStreamController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  bool _isOnlineConnected = false;
  bool get isOnlineConnected => _isOnlineConnected;

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

  Future<void> connectOnline(String url) async {
    if (_isOnlineConnected && _onlineChannel != null) {
      appLog.info('Online socket is already connected.');
      return;
    }

    try {
      appLog.info('Connecting to online WebSocket: $url');
      _onlineChannel = WebSocketChannel.connect(Uri.parse(url));
      _isOnlineConnected = true;

      _onlineChannel!.stream.listen(
        (message) {
          appLog.info('ONLINE WS Received: $message');
          _parseOnlineMessage(message);
        },
        onError: (error) {
          appLog.error('ONLINE WS Error: $error');
          _isOnlineConnected = false;
        },
        onDone: () {
          appLog.info('ONLINE WS Disconnected');
          _isOnlineConnected = false;
        },
      );
    } catch (e) {
      appLog.error('ONLINE WS Connection Exception: $e');
      _isOnlineConnected = false;
    }
  }

  void joinOnline({required int userSysId}) {
    if (!_isOnlineConnected || _onlineChannel == null) {
      appLog.warning('Online socket not connected. Cannot join online.');
      return;
    }

    final message = {
      'type': 'JOIN_ONLINE',
      'payload': {'user_sys_id': userSysId.toString()},
    };

    final jsonMessage = jsonEncode(message);
    appLog.info('ONLINE WS Sending: $jsonMessage');
    _onlineChannel!.sink.add(jsonMessage);
  }

  void leaveOnline({required int userSysId}) {
    if (!_isOnlineConnected || _onlineChannel == null) {
      return;
    }

    final message = {
      'type': 'LEAVE_ONLINE',
      'payload': {'user_sys_id': userSysId.toString()},
    };

    final jsonMessage = jsonEncode(message);
    appLog.info('ONLINE WS Sending: $jsonMessage');
    _onlineChannel!.sink.add(jsonMessage);
  }

  bool subscribeOnlineStatus({required Iterable<int> userSysIds}) {
    if (!_isOnlineConnected || _onlineChannel == null) {
      appLog.warning(
        'Online socket not connected. Cannot subscribe online status.',
      );
      return false;
    }

    final ids =
        userSysIds
            .where((id) => id > 0)
            .map((id) => id.toString())
            .toSet()
            .toList();
            
    appLog.info('ONLINE WS Subscribing to user_sys_ids: $ids');

    if (ids.isEmpty) {
      appLog.info('Skip ONLINE_SUBSCRIBE because user list is empty.');
      return false;
    }

    final message = {
      'type': 'ONLINE_SUBSCRIBE',
      'payload': {'user_sys_ids': ids},
    };

    final jsonMessage = jsonEncode(message);
    appLog.info('ONLINE WS Sending: $jsonMessage');
    _onlineChannel!.sink.add(jsonMessage);
    return true;
  }

  void joinRoom({required int userId, required int chatId}) {
    if (!_isConnected || _channel == null) {
      appLog.warning('Socket not connected. Cannot join room.');
      return;
    }

    final message = {
      'type': 'JOIN_ROOM',
      'payload': {'user_id': userId.toString(), 'chat_id': chatId.toString()},
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

  WebSocketChannel? _qaChannel;

  final StreamController<dynamic> _qaStreamController =
      StreamController<dynamic>.broadcast();
  Stream<dynamic> get qaStream => _qaStreamController.stream;

  bool _isQaConnected = false;
  bool get isQaConnected => _isQaConnected;

  Timer? _qaPingTimer;
  Timer? _qaReconnectTimer;
  String? _qaUrl;
  int _qaReconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _pingInterval = Duration(seconds: 25);

  Future<void> connectQaLive(String url) async {
    if (_isQaConnected && _qaChannel != null) {
      return;
    }

    _qaUrl = url;
    _qaReconnectAttempts = 0;
    await _doConnectQaLive(url);
  }

  Future<void> _doConnectQaLive(String url) async {
    try {
      _qaChannel = WebSocketChannel.connect(Uri.parse(url));
      _isQaConnected = true;
      _qaReconnectAttempts = 0;

      // Setup keep-alive ping
      _setupQaPingTimer();

      _qaChannel!.stream.listen(
        (message) {
          _parseQaMessage(message);
        },
        onError: (e) {
          _isQaConnected = false;
          appLog.error("QA socket error: $e");
          _attemptQaReconnect();
        },
        onDone: () {
          _isQaConnected = false;
          _attemptQaReconnect();
        },
      );
    } catch (e) {
      appLog.error('DEBUG [Socket]: QA Socket connection exception: $e');
      _isQaConnected = false;
      _attemptQaReconnect();
    }
  }

  void _setupQaPingTimer() {
    _qaPingTimer?.cancel();
    _qaPingTimer = Timer.periodic(_pingInterval, (_) {
      if (_isQaConnected && _qaChannel != null) {
        try {
          appLog.info('DEBUG [Socket]: Sending keep-alive PING');
          _qaChannel!.sink.add(jsonEncode({'type': 'PING'}));
        } catch (e) {
          appLog.error('DEBUG [Socket]: PING failed: $e');
        }
      }
    });
  }

  void _attemptQaReconnect() {
    _qaPingTimer?.cancel();
    _qaReconnectTimer?.cancel();

    if (_qaReconnectAttempts >= _maxReconnectAttempts) {
      appLog.warning(
        'DEBUG [Socket]: Max reconnect attempts reached, giving up',
      );
      return;
    }

    _qaReconnectAttempts++;
    appLog.info(
      'DEBUG [Socket]: Scheduling reconnect attempt $_qaReconnectAttempts/$_maxReconnectAttempts in ${_reconnectDelay.inSeconds}s',
    );

    _qaReconnectTimer = Timer(_reconnectDelay, () {
      if (_qaUrl != null && !_isQaConnected) {
        appLog.info(
          'DEBUG [Socket]: Executing reconnect attempt $_qaReconnectAttempts',
        );
        unawaited(_doConnectQaLive(_qaUrl!));
      }
    });
  }

  void joinQaLive({required int userId, required int qaLiveId}) {
    appLog.info(
      'DEBUG [Socket]: joinQaLive called - isConnected=$_isQaConnected, channelNull=${_qaChannel == null}, userId=$userId, qaLiveId=$qaLiveId',
    );
    if (!_isQaConnected || _qaChannel == null) {
      appLog.info(
        'DEBUG [Socket]: joinQaLive ignoring - not connected or no channel',
      );
      return;
    }

    final message = {
      'type': 'JOIN_LIVE',
      'payload': {
        'user_id': userId.toString(),
        'user_id_str': userId.toString(),
        'user_sys_id': userId,
        'qa_live_id': qaLiveId.toString(),
        'qa_live_id_str': qaLiveId.toString(),
        'live_id': qaLiveId,
      },
    };

    appLog.info('DEBUG [Socket]: Sending JOIN_LIVE message');
    _qaChannel!.sink.add(jsonEncode(message));
  }

  void joinQaSectionRoom({required int userId, required int sectionId}) {
    appLog.info(
      'DEBUG [Socket]: joinQaSectionRoom called - isConnected=$_isQaConnected, channelNull=${_qaChannel == null}, userId=$userId, sectionId=$sectionId',
    );
    if (!_isQaConnected || _qaChannel == null) {
      appLog.info(
        'DEBUG [Socket]: joinQaSectionRoom ignoring - not connected or no channel',
      );
      return;
    }

    final message = {
      'type': 'JOIN_SECTION_ROOM',
      'payload': {
        // Backend expects string fields for join payload.
        'user_id': userId.toString(),
        'user_id_str': userId.toString(),
        'user_sys_id': userId,
        'section_id': sectionId.toString(),
        'section_id_str': sectionId.toString(),
      },
    };

    appLog.info(
      'DEBUG [Socket]: Sending JOIN_SECTION_ROOM message for sectionId=$sectionId',
    );
    _qaChannel!.sink.add(jsonEncode(message));
  }

  void leaveQaLive({required int userId, required int qaLiveId}) {
    if (!_isQaConnected || _qaChannel == null) return;

    final message = {
      'type': 'LEAVE_LIVE',
      'payload': {
        'user_id': userId.toString(),
        'qa_live_id': qaLiveId.toString(),
      },
    };

    _qaChannel!.sink.add(jsonEncode(message));
  }

  void leaveQaSectionRoom({required int userId, required int sectionId}) {
    if (!_isQaConnected || _qaChannel == null) return;

    final message = {
      'type': 'LEAVE_SECTION_ROOM',
      'payload': {
        'user_id': userId.toString(),
        'section_id': sectionId.toString(),
      },
    };

    _qaChannel!.sink.add(jsonEncode(message));
  }

  void syncSlide({
    required int slideNumber,
    required String qaLiveId,
    required int userId,
  }) {
    if (!_isQaConnected || _qaChannel == null) return;

    final message = {
      'type': 'SLIDE_SYNC',
      'payload': {
        'slide_number': slideNumber,
        'qa_live_id': qaLiveId,
        'user_id': userId.toString(),
      },
    };

    _qaChannel!.sink.add(jsonEncode(message));
  }

  void upvoteQuestion({required String questionId}) {
    if (!_isQaConnected || _qaChannel == null) return;

    final message = {
      'type': 'QA_UPVOTED',
      'payload': {'question_id': questionId},
    };

    _qaChannel!.sink.add(jsonEncode(message));
  }

  void postQuestion({
    required String content,
    required int qaLiveId,
    int? askerId,
    int? postId,
    int? attachmentId,
    int? slideNumber,
    bool? isAnonymous,
  }) {
    if (!_isQaConnected || _qaChannel == null) return;

    final message = {
      'type': 'QA_NEW_QUESTION',
      'payload': {
        'content': content,
        'question': content,
        'qa_live_id': qaLiveId.toString(),
        if (askerId != null) 'asker_id': askerId,
        if (postId != null) 'post_id': postId,
        if (attachmentId != null) 'attachment_id': attachmentId,
        if (slideNumber != null) 'slide_number': slideNumber,
        if (isAnonymous != null) 'is_anonymous': isAnonymous,
      },
    };

    _qaChannel!.sink.add(jsonEncode(message));
  }

  void sendQaMessage(Map<String, dynamic> message) {
    if (_isQaConnected && _qaChannel != null) {
      _qaChannel!.sink.add(jsonEncode(message));
    }
  }

  void _parseQaMessage(String message) {
    try {
      final decoded = jsonDecode(message);
      final msgType = decoded['type'];
      appLog.info(
        'DEBUG [Socket]: QA message received - type=$msgType, has_payload=${decoded['payload'] != null}, payload_keys=${(decoded['payload'] as Map?)?.keys.toList() ?? []}',
      );

      if (!_qaStreamController.isClosed) {
        _qaStreamController.add(decoded);
      } else {
        appLog.info('DEBUG [Socket]: QA Stream is CLOSED, discarding message');
      }
    } catch (e) {
      appLog.info('DEBUG [Socket]: QA parse error: $e');
      appLog.error("QA parse error: $e");
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

  void _parseOnlineMessage(dynamic message) {
    try {
      dynamic decoded = message;
      if (message is String) {
        decoded = jsonDecode(message);
      }

      if (!_onlineStreamController.isClosed) {
        _onlineStreamController.add(decoded);
      }
    } catch (e) {
      appLog.error('Error decoding ONLINE WS message: $e');
      if (!_onlineStreamController.isClosed) {
        _onlineStreamController.add(message);
      }
    }
  }

  void disconnect() {
    if (_isConnected) {
      _channel?.sink.close();
      _isConnected = false;
      appLog.info('Socket manual disconnect');
    }
  }

  void disconnectOnline() {
    if (_isOnlineConnected) {
      _onlineChannel?.sink.close();
      _onlineChannel = null;
      _isOnlineConnected = false;
      appLog.info('Online socket manual disconnect');
    }
  }

  void disconnectQa() {
    appLog.info('DEBUG [Socket]: disconnectQa called');
    _qaPingTimer?.cancel();
    _qaReconnectTimer?.cancel();
    if (_qaChannel != null) {
      _qaChannel!.sink.close();
      _qaChannel = null;
    }
    _isQaConnected = false;
    _qaReconnectAttempts = 0;
  }

  void dispose() {
    disconnect();
    disconnectOnline();
    disconnectQa();
    _socketResponseController.close();
    _onlineStreamController.close();
    _qaStreamController.close();
  }
}
