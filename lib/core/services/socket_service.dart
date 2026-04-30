import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:LinkLian/core/utils/logger.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  // Chat socket
  WebSocketChannel? _chatChannel;
  final StreamController<dynamic> _chatStreamController =
      StreamController<dynamic>.broadcast();
  Stream<dynamic> get chatStream => _chatStreamController.stream;

  bool _isChatConnected = false;
  bool get isChatConnected => _isChatConnected;

  Timer? _chatReconnectTimer;
  String? _chatUrl;
  int _chatReconnectAttempts = 0;
  bool _isChatConnecting = false;
  bool _chatShouldReconnect = false;
  int? _chatWaitingUserId;
  int? _chatRoomUserId;
  final Set<int> _chatJoinedChatIds = <int>{};
  static const Duration _chatBaseReconnectDelay = Duration(seconds: 2);
  static const Duration _chatMaxReconnectDelay = Duration(seconds: 30);

  // Online socket
  WebSocketChannel? _onlineChannel;
  final StreamController<dynamic> _onlineStreamController =
      StreamController<dynamic>.broadcast();
  Stream<dynamic> get onlineStream => _onlineStreamController.stream;
  bool _isOnlineConnected = false;
  bool get isOnlineConnected => _isOnlineConnected;

  Timer? _onlineReconnectTimer;
  String? _onlineUrl;
  int _onlineReconnectAttempts = 0;
  bool _isOnlineConnecting = false;
  bool _onlineShouldReconnect = false;
  int? _onlineJoinedUserId;
  final Set<int> _onlineSubscribedUserIds = <int>{};
  static const Duration _onlineBaseReconnectDelay = Duration(seconds: 2);
  static const Duration _onlineMaxReconnectDelay = Duration(seconds: 30);

  Future<void> connectChat(String url) async {
    _chatUrl = url;
    _chatShouldReconnect = true;

    if (_isChatConnected && _chatChannel != null) {
      appLog.info('Socket is already connected.');
      return;
    }

    if (_isChatConnecting) {
      appLog.info('Chat socket is connecting.');
      return;
    }

    _chatReconnectTimer?.cancel();
    await _doConnectChat(url);
  }

  Future<void> _doConnectChat(String url) async {
    if (_isChatConnecting) return;
    _isChatConnecting = true;

    try {
      appLog.info('Connecting to WebSocket: $url');
      _chatChannel = WebSocketChannel.connect(Uri.parse(url));
      _isChatConnected = true;
      _chatReconnectAttempts = 0;
      _restoreChatSession();

      _chatChannel!.stream.listen(
        (message) {
          appLog.info('WS Received: $message');
          // Use async parsing to avoid blocking main thread
          _parseChatMessageAsync(message);
        },
        onError: (error) {
          appLog.error('WS Error: $error');
          _isChatConnected = false;
          _chatChannel = null;
          _scheduleChatReconnect();
        },
        onDone: () {
          appLog.info('WS Disconnected');
          _isChatConnected = false;
          _chatChannel = null;
          _scheduleChatReconnect();
        },
      );
    } catch (e) {
      appLog.error('WS Connection Exception: $e');
      _isChatConnected = false;
      _chatChannel = null;
      _scheduleChatReconnect();
    } finally {
      _isChatConnecting = false;
    }
  }

  void _restoreChatSession() {
    if (!_isChatConnected || _chatChannel == null) {
      return;
    }

    if (_chatWaitingUserId != null) {
      final message = {
        'type': 'JOIN_WAITING',
        'payload': {'user_id': _chatWaitingUserId.toString()},
      };
      sendChatMessage(message);
    }

    if (_chatRoomUserId != null && _chatJoinedChatIds.isNotEmpty) {
      for (final chatId in _chatJoinedChatIds) {
        if (chatId <= 0) continue;
        final message = {
          'type': 'JOIN_ROOM',
          'payload': {
            'user_id': _chatRoomUserId.toString(),
            'chat_id': chatId.toString(),
          },
        };
        sendChatMessage(message);
      }
    }
  }

  void _scheduleChatReconnect() {
    if (!_chatShouldReconnect || _chatUrl == null) {
      return;
    }

    _chatReconnectTimer?.cancel();
    _chatReconnectAttempts++;

    final backoffSeconds =
        _chatBaseReconnectDelay.inSeconds *
        (1 << (_chatReconnectAttempts - 1).clamp(0, 4));
    final delaySeconds =
        backoffSeconds > _chatMaxReconnectDelay.inSeconds
            ? _chatMaxReconnectDelay.inSeconds
            : backoffSeconds;
    final delay = Duration(seconds: delaySeconds);

    appLog.info(
      'CHAT WS Reconnect attempt $_chatReconnectAttempts scheduled in ${delay.inSeconds}s',
    );

    _chatReconnectTimer = Timer(delay, () {
      if (_chatShouldReconnect && !_isChatConnected && _chatUrl != null) {
        unawaited(_doConnectChat(_chatUrl!));
      }
    });
  }

  Future<void> connectOnline(String url) async {
    _onlineUrl = url;
    _onlineShouldReconnect = true;

    if (_isOnlineConnected && _onlineChannel != null) {
      appLog.info('Online socket is already connected.');
      return;
    }

    if (_isOnlineConnecting) {
      appLog.info('Online socket is connecting.');
      return;
    }

    _onlineReconnectTimer?.cancel();
    await _doConnectOnline(url);
  }

  Future<void> _doConnectOnline(String url) async {
    if (_isOnlineConnecting) return;
    _isOnlineConnecting = true;

    try {
      appLog.info('Connecting to online WebSocket: $url');
      _onlineChannel = WebSocketChannel.connect(Uri.parse(url));
      _isOnlineConnected = true;
      _onlineReconnectAttempts = 0;
      _restoreOnlineSession();

      _onlineChannel!.stream.listen(
        (message) {
          appLog.info('ONLINE WS Received: $message');
          _parseOnlineMessage(message);
        },
        onError: (error) {
          appLog.error('ONLINE WS Error: $error');
          _isOnlineConnected = false;
          _onlineChannel = null;
          _scheduleOnlineReconnect();
        },
        onDone: () {
          appLog.info('ONLINE WS Disconnected');
          _isOnlineConnected = false;
          _onlineChannel = null;
          _scheduleOnlineReconnect();
        },
      );
    } catch (e) {
      appLog.error('ONLINE WS Connection Exception: $e');
      _isOnlineConnected = false;
      _onlineChannel = null;
      _scheduleOnlineReconnect();
    } finally {
      _isOnlineConnecting = false;
    }
  }

  void _restoreOnlineSession() {
    if (!_isOnlineConnected || _onlineChannel == null) {
      return;
    }

    if (_onlineJoinedUserId != null) {
      final message = {
        'type': 'JOIN_ONLINE',
        'payload': {'user_sys_id': _onlineJoinedUserId.toString()},
      };
      final jsonMessage = jsonEncode(message);
      appLog.info('ONLINE WS Restoring JOIN_ONLINE: $jsonMessage');
      _onlineChannel!.sink.add(jsonMessage);
    }

    if (_onlineSubscribedUserIds.isNotEmpty) {
      final ids =
          _onlineSubscribedUserIds
              .where((id) => id > 0)
              .map((id) => id.toString())
              .toList();

      final message = {
        'type': 'ONLINE_SUBSCRIBE',
        'payload': {'user_sys_ids': ids},
      };

      final jsonMessage = jsonEncode(message);
      appLog.info('ONLINE WS Restoring ONLINE_SUBSCRIBE: $jsonMessage');
      _onlineChannel!.sink.add(jsonMessage);
    }
  }

  void _scheduleOnlineReconnect() {
    if (!_onlineShouldReconnect || _onlineUrl == null) {
      return;
    }

    _onlineReconnectTimer?.cancel();
    _onlineReconnectAttempts++;

    final backoffSeconds =
        _onlineBaseReconnectDelay.inSeconds *
        (1 << (_onlineReconnectAttempts - 1).clamp(0, 4));
    final delaySeconds =
        backoffSeconds > _onlineMaxReconnectDelay.inSeconds
            ? _onlineMaxReconnectDelay.inSeconds
            : backoffSeconds;
    final delay = Duration(seconds: delaySeconds);

    appLog.info(
      'ONLINE WS Reconnect attempt $_onlineReconnectAttempts scheduled in ${delay.inSeconds}s',
    );

    _onlineReconnectTimer = Timer(delay, () {
      if (_onlineShouldReconnect && !_isOnlineConnected && _onlineUrl != null) {
        unawaited(_doConnectOnline(_onlineUrl!));
      }
    });
  }

  void joinOnline({required int userSysId}) {
    _onlineJoinedUserId = userSysId;

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
    if (_onlineJoinedUserId == userSysId) {
      _onlineJoinedUserId = null;
    }

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
    final idsSet = userSysIds.where((id) => id > 0).toSet();
    _onlineSubscribedUserIds.addAll(idsSet);

    if (!_isOnlineConnected || _onlineChannel == null) {
      appLog.warning(
        'Online socket not connected. Cannot subscribe online status.',
      );
      return false;
    }

    final ids =
        _onlineSubscribedUserIds
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

  void joinChatRoom({required int userId, required int chatId}) {
    if (chatId > 0) {
      _chatJoinedChatIds.add(chatId);
    }
    if (userId > 0) {
      _chatRoomUserId = userId;
    }

    if (!_isChatConnected || _chatChannel == null) {
      appLog.warning('Socket not connected. Cannot join room.');
      return;
    }

    final message = {
      'type': 'JOIN_ROOM',
      'payload': {'user_id': userId.toString(), 'chat_id': chatId.toString()},
    };

    sendChatMessage(message);
  }

  void joinChatWaiting({required int userId}) {
    if (userId > 0) {
      _chatWaitingUserId = userId;
    }

    if (!_isChatConnected || _chatChannel == null) {
      appLog.warning('Socket not connected. Cannot join waiting.');
      return;
    }

    final message = {
      'type': 'JOIN_WAITING',
      'payload': {'user_id': userId.toString()},
    };

    sendChatMessage(message);

    appLog.info('CHAT WAITING Subscribe: $message');
  }

  void sendChatMessage(Map<String, dynamic> message) {
    if (_isChatConnected && _chatChannel != null) {
      final jsonMessage = jsonEncode(message);
      appLog.info('WS Sending: $jsonMessage');
      _chatChannel!.sink.add(jsonMessage);
    } else {
      appLog.warning('Socket not connected. Cannot send message.');
    }
  }

  // QA socket
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
  static const int _maxReconnectAttempts = -1; // -1 = ไม่จำกัดครั้ง
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

    if (_maxReconnectAttempts > 0 && _qaReconnectAttempts >= _maxReconnectAttempts) {
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
  Future<void> _parseChatMessageAsync(String message) async {
    try {
      // Schedule JSON parsing on next frame to avoid blocking current frame
      Future.microtask(() {
        try {
          final decoded = jsonDecode(message);
          if (!_chatStreamController.isClosed) {
            _chatStreamController.add(decoded);
          }
        } catch (e) {
          appLog.error('Error decoding WS message: $e');
          // If it's not JSON, pass it as is or handle accordingly
          if (!_chatStreamController.isClosed) {
            _chatStreamController.add(message);
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

  void disconnectChat() {
    _chatShouldReconnect = false;
    _chatReconnectTimer?.cancel();
    _chatReconnectAttempts = 0;
    _isChatConnecting = false;
    _chatUrl = null;
    _chatWaitingUserId = null;
    _chatRoomUserId = null;
    _chatJoinedChatIds.clear();

    if (_isChatConnected) {
      _chatChannel?.sink.close();
      _isChatConnected = false;
      appLog.info('Socket manual disconnect');
    }
  }

  void disconnectOnline() {
    _onlineShouldReconnect = false;
    _onlineReconnectTimer?.cancel();
    _onlineReconnectAttempts = 0;
    _isOnlineConnecting = false;
    _onlineUrl = null;
    _onlineJoinedUserId = null;
    _onlineSubscribedUserIds.clear();

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
    disconnectChat();
    disconnectOnline();
    disconnectQa();
    _chatStreamController.close();
    _onlineStreamController.close();
    _qaStreamController.close();
  }
}
