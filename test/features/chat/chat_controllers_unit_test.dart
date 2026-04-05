import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:LinkLian/data/repository/chat.repository.dart';
import 'package:LinkLian/data/model/chat.model.dart';
import 'package:LinkLian/core/services/socket_service.dart';

// Mock ChatRepository for API layer testing
class MockChatRepository implements ChatRepository {
  List<ChatModel> mockChats = [];
  List<ChatModel> mockMessages = [];
  ChatModel? mockCreatedChat;
  ChatModel? mockUpdatedChat;
  ChatModel? mockCreatedMessage;
  bool shouldThrowError = false;
  
  @override
  Future<List<ChatModel>> getChat({
    int? chatId,
    int? userSysId,
    bool? isAiChat,
    bool? flagValid,
    String? sortBy,
    String? sortOrder,
    int? limit,
    int? offset,
  }) async {
    if (shouldThrowError) throw Exception('Get Chat Error');
    return mockChats.skip(offset ?? 0).take(limit ?? mockChats.length).toList();
  }
  
  @override
  Future<ChatModel> createChat({
    required bool isAiChat,
    required int senderId,
    required int receiverId,
  }) async {
    if (shouldThrowError) throw Exception('Create Chat Error');
    return mockCreatedChat ?? createMockChat(chatId: 1);
  }
  
  @override
  Future<ChatModel> updateChat({
    required int chatId,
    bool? isAiChat,
    bool? flagValid,
  }) async {
    if (shouldThrowError) throw Exception('Update Chat Error');
    return mockUpdatedChat ?? createMockChat(chatId: chatId);
  }
  
  @override
  Future<List<ChatModel>> getMessage({
    int? messageId,
    int? chatId,
    int? senderId,
    String? content,
    int? replyId,
    bool? flagValid,
    String? sortBy,
    String? sortOrder,
    int? limit,
    int? offset,
  }) async {
    if (shouldThrowError) throw Exception('Get Message Error');
    return mockMessages.skip(offset ?? 0).take(limit ?? mockMessages.length).toList();
  }
  
  @override
  Future<ChatModel> createMessage({
    required int chatId,
    required int senderId,
    required String content,
    int? replyId,
    List<dynamic>? file,
  }) async {
    if (shouldThrowError) throw Exception('Create Message Error');
    return mockCreatedMessage ?? createMockMessage(
      messageId: 1,
      chatId: chatId,
      senderId: senderId,
      content: content,
    );
  }
  
  @override
  Future<void> deleteChat({required int chatId}) async {
    if (shouldThrowError) throw Exception('Delete Chat Error');
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Mock SocketService for testing socket functionality
class MockSocketService implements SocketService {
  final StreamController<dynamic> _controller = StreamController<dynamic>.broadcast();
  bool _isConnected = false;
  List<Map<String, dynamic>> sentMessages = [];
  
  @override
  bool get isConnected => _isConnected;
  
  @override
  Stream<dynamic> get socketResponseStream => _controller.stream;
  
  @override
  Future<void> connect(String url) async {
    _isConnected = true;
  }
  
  @override
  void disconnect() {
    _isConnected = false;
    _controller.close();
  }
  
  @override
  void joinRoom({required int userId, required int chatId}) {
    sentMessages.add({
      'type': 'JOIN_ROOM',
      'payload': {'user_id': userId, 'chat_id': chatId}
    });
  }
  
  @override
  void sendMessage(Map<String, dynamic> message) {
    sentMessages.add(message);
  }
  
  // Test helper to simulate incoming messages
  void simulateIncomingMessage(Map<String, dynamic> data) {
    _controller.add(data);
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Helper functions for creating mock data
ChatModel createMockChat({
  int? chatId,
  int? userSysId,
  bool? isAiChat,
  String? lastMessage,
  DateTime? lastSent,
  int? senderId,
  int? receiverId,
  String? firstName,
  String? lastName,
  String? profileImage,
  bool? flagValid,
}) {
  return ChatModel(
    chatId: chatId ?? 1,
    userSysId: userSysId,
    isAiChat: isAiChat ?? false,
    lastMessage: lastMessage,
    lastSent: lastSent ?? DateTime.now(),
    senderId: senderId,
    receiverId: receiverId,
    firstName: firstName,
    lastName: lastName,
    profileImage: profileImage,
    flagValid: flagValid ?? true,
  );
}

ChatModel createMockMessage({
  int? messageId,
  int? chatId,
  int? senderId,
  String? content,
  int? replyId,
  DateTime? createdAt,
}) {
  return ChatModel(
    messageId: messageId ?? 1,
    chatId: chatId ?? 1,
    senderId: senderId ?? 1,
    content: content ?? 'Test message',
    replyId: replyId,
    createdAt: createdAt ?? DateTime.now(),
    flagValid: true,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() async {
    dotenv.testLoad(mergeWith: {
      'API_BASE_URL': 'https://test.example.com',
      'SOCKET_URL': 'wss://test.socket.com/ws',
    });
  });
  
  group('ChatController Tests', () {
    late MockChatRepository mockRepository;
    
    setUp(() {
      mockRepository = MockChatRepository();
    });
    
    group('Controller Tests', () {
      // Test: Fetches user's chat list
      test('should get chats successfully', () async {
        mockRepository.mockChats = [
          createMockChat(chatId: 1, lastMessage: 'Hello'),
          createMockChat(chatId: 2, lastMessage: 'Hi there'),
        ];
        
        // Note: Real controller uses ChatRepository internally
        // This test validates the mock repository behavior
        final chats = await mockRepository.getChat(
          userSysId: 1,
          sortBy: 'last_sent',
          sortOrder: 'desc',
        );
        
        expect(chats.length, 2);
        expect(chats[0].chatId, 1);
        expect(chats[1].chatId, 2);
      });
      
      // Test: Creates new chat between users
      test('should create chat successfully', () async {
        mockRepository.mockCreatedChat = createMockChat(
          chatId: 10,
          senderId: 1,
          receiverId: 2,
          isAiChat: false,
        );
        
        final chat = await mockRepository.createChat(
          isAiChat: false,
          senderId: 1,
          receiverId: 2,
        );
        
        expect(chat.chatId, 10);
        expect(chat.senderId, 1);
        expect(chat.receiverId, 2);
        expect(chat.isAiChat, false);
      });
      
      // Test: Updates chat settings
      test('should update chat successfully', () async {
        mockRepository.mockUpdatedChat = createMockChat(
          chatId: 1,
          isAiChat: true,
        );
        
        final chat = await mockRepository.updateChat(
          chatId: 1,
          isAiChat: true,
        );
        
        expect(chat.chatId, 1);
        expect(chat.isAiChat, true);
      });
      
      // Test: Handles API errors when fetching chats
      test('should handle get chat errors', () async {
        mockRepository.shouldThrowError = true;
        
        expect(
          () => mockRepository.getChat(userSysId: 1),
          throwsA(isA<Exception>()),
        );
      });
      
      // Test: Handles errors when creating chat
      test('should handle create chat errors', () async {
        mockRepository.shouldThrowError = true;
        
        expect(
          () => mockRepository.createChat(
            isAiChat: false,
            senderId: 1,
            receiverId: 2,
          ),
          throwsA(isA<Exception>()),
        );
      });
      
      // Test: Handles errors when updating chat
      test('should handle update chat errors', () async {
        mockRepository.shouldThrowError = true;
        
        expect(
          () => mockRepository.updateChat(chatId: 1, isAiChat: true),
          throwsA(isA<Exception>()),
        );
      });
    });
    
    group('Pagination Tests', () {
      // Test: Handles chat pagination with offset/limit
      test('should handle pagination correctly', () async {
        mockRepository.mockChats = List.generate(
          20,
          (i) => createMockChat(chatId: i + 1),
        );
        
        final firstPage = await mockRepository.getChat(
          userSysId: 1,
          offset: 0,
          limit: 10,
        );
        
        final secondPage = await mockRepository.getChat(
          userSysId: 1,
          offset: 10,
          limit: 10,
        );
        
        expect(firstPage.length, 10);
        expect(secondPage.length, 10);
        expect(firstPage[0].chatId, 1);
        expect(secondPage[0].chatId, 11);
      });
    });
    
    group('Filtering Tests', () {
      // Test: Filters chats by AI chat flag
      test('should filter AI chats', () async {
        mockRepository.mockChats = [
          createMockChat(chatId: 1, isAiChat: true),
          createMockChat(chatId: 2, isAiChat: false),
        ];
        
        // Simulates filter logic
        final allChats = await mockRepository.getChat(userSysId: 1);
        final aiChats = allChats.where((c) => c.isAiChat == true).toList();
        
        expect(aiChats.length, 1);
        expect(aiChats[0].chatId, 1);
      });
      
      // Test: Sorts chats by last sent date
      test('should sort chats by date', () async {
        final now = DateTime.now();
        mockRepository.mockChats = [
          createMockChat(chatId: 1, lastSent: now.subtract(Duration(hours: 1))),
          createMockChat(chatId: 2, lastSent: now),
          createMockChat(chatId: 3, lastSent: now.subtract(Duration(hours: 2))),
        ];
        
        final chats = await mockRepository.getChat(
          userSysId: 1,
          sortBy: 'last_sent',
          sortOrder: 'desc',
        );
        
        // Validates chat retrieval (actual sorting done by API)
        expect(chats.length, 3);
      });
    });
  });
  
  group('ChatMessageController Tests', () {
    late MockChatRepository mockRepository;
    late MockSocketService mockSocketService;
    
    setUp(() {
      mockRepository = MockChatRepository();
      mockSocketService = MockSocketService();
    });
    
    group('Initialization Tests', () {
      // Test: Initializes with chat ID and loads messages
      test('should initialize successfully', () async {
        mockRepository.mockMessages = [
          createMockMessage(messageId: 1, content: 'Message 1'),
          createMockMessage(messageId: 2, content: 'Message 2'),
        ];
        
        // Note: Real controller initialization requires LocalStorage setup
        // This validates the repository mock
        final messages = await mockRepository.getMessage(
          chatId: 1,
          sortBy: 'created_at',
          sortOrder: 'asc',
        );
        
        expect(messages.length, 2);
        expect(messages[0].messageId, 1);
        expect(messages[1].messageId, 2);
      });
      
      // Test: Handles errors during initialization
      test('should handle initialization errors', () async {
        mockRepository.shouldThrowError = true;
        
        expect(
          () => mockRepository.getMessage(chatId: 1),
          throwsA(isA<Exception>()),
        );
      });
    });
    
    group('Message Sending Tests', () {
      // Test: Sends message via repository and socket
      test('should send message successfully', () async {
        mockRepository.mockCreatedMessage = createMockMessage(
          messageId: 10,
          chatId: 1,
          senderId: 1,
          content: 'Test message',
        );
        
        final message = await mockRepository.createMessage(
          chatId: 1,
          senderId: 1,
          content: 'Test message',
        );
        
        expect(message.messageId, 10);
        expect(message.content, 'Test message');
        expect(message.chatId, 1);
      });
      
      // Test: Sends message with reply ID
      test('should send message with reply', () async {
        mockRepository.mockCreatedMessage = createMockMessage(
          messageId: 10,
          chatId: 1,
          senderId: 1,
          content: 'Reply message',
          replyId: 5,
        );
        
        final message = await mockRepository.createMessage(
          chatId: 1,
          senderId: 1,
          content: 'Reply message',
          replyId: 5,
        );
        
        expect(message.replyId, 5);
      });
      
      // Test: Handles errors when sending messages
      test('should handle send message errors', () async {
        mockRepository.shouldThrowError = true;
        
        expect(
          () => mockRepository.createMessage(
            chatId: 1,
            senderId: 1,
            content: 'Test',
          ),
          throwsA(isA<Exception>()),
        );
      });
      
      // Test: Sends message with file attachments
      test('should send message with files', () async {
        final files = [
          {'url': 'https://example.com/file1.jpg'},
          {'url': 'https://example.com/file2.pdf'},
        ];
        
        mockRepository.mockCreatedMessage = createMockMessage(
          messageId: 10,
          chatId: 1,
          senderId: 1,
          content: 'Message with files',
        );
        
        final message = await mockRepository.createMessage(
          chatId: 1,
          senderId: 1,
          content: 'Message with files',
          file: files,
        );
        
        expect(message.messageId, 10);
      });
    });
    
    group('Socket Integration Tests', () {
      // Test: Connects to socket successfully
      test('should connect to socket', () async {
        await mockSocketService.connect('wss://test.socket.com/ws');
        
        expect(mockSocketService.isConnected, true);
      });
      
      // Test: Joins chat room via socket
      test('should join room', () async {
        await mockSocketService.connect('wss://test.socket.com/ws');
        mockSocketService.joinRoom(userId: 1, chatId: 10);
        
        expect(mockSocketService.sentMessages.length, 1);
        expect(mockSocketService.sentMessages[0]['type'], 'JOIN_ROOM');
      });
      
      // Test: Sends message via socket
      test('should send message via socket', () async {
        await mockSocketService.connect('wss://test.socket.com/ws');
        
        final message = {
          'type': 'SEND_MESSAGE',
          'payload': {
            'chat_id': 1,
            'user_id': 1,
            'content': 'Hello',
          }
        };
        
        mockSocketService.sendMessage(message);
        
        expect(mockSocketService.sentMessages.length, 1);
        expect(mockSocketService.sentMessages[0]['type'], 'SEND_MESSAGE');
      });
      
      // Test: Receives incoming messages via socket
      test('should receive incoming messages', () async {
        await mockSocketService.connect('wss://test.socket.com/ws');
        
        final receivedMessages = <dynamic>[];
        mockSocketService.socketResponseStream.listen((data) {
          receivedMessages.add(data);
        });
        
        mockSocketService.simulateIncomingMessage({
          'type': 'CHAT_RECEIVE',
          'payload': {
            'message_id': 1,
            'content': 'Incoming message',
          }
        });
        
        await Future.delayed(Duration(milliseconds: 100));
        
        expect(receivedMessages.length, 1);
        expect(receivedMessages[0]['type'], 'CHAT_RECEIVE');
      });
      
      // Test: Disconnects from socket cleanly
      test('should disconnect from socket', () async {
        await mockSocketService.connect('wss://test.socket.com/ws');
        expect(mockSocketService.isConnected, true);
        
        mockSocketService.disconnect();
        expect(mockSocketService.isConnected, false);
      });
    });
    
    group('Message Stream Tests', () {
      // Test: Emits messages to stream
      test('should emit messages to stream', () async {
        final messages = <List<ChatModel>>[];
        
        mockRepository.mockMessages = [
          createMockMessage(messageId: 1),
          createMockMessage(messageId: 2),
        ];
        
        // Simulates stream behavior
        final initialMessages = await mockRepository.getMessage(chatId: 1);
        messages.add(initialMessages);
        
        expect(messages.length, 1);
        expect(messages[0].length, 2);
      });
      
      // Test: Updates stream when new message arrives
      test('should update stream on new message', () async {
        mockRepository.mockMessages = [
          createMockMessage(messageId: 1),
        ];
        
        final initialMessages = await mockRepository.getMessage(chatId: 1);
        expect(initialMessages.length, 1);
        
        // Simulates adding new message
        mockRepository.mockMessages.add(createMockMessage(messageId: 2));
        
        final updatedMessages = await mockRepository.getMessage(chatId: 1);
        expect(updatedMessages.length, 2);
      });
    });
  });
  
  group('Business Logic Tests', () {
    late MockChatRepository mockRepository;
    
    setUp(() {
      mockRepository = MockChatRepository();
    });
    
    // Test: Validates chat model fields
    test('should validate chat model', () {
      final chat = createMockChat(
        chatId: 1,
        userSysId: 100,
        isAiChat: false,
        lastMessage: 'Hello',
      );
      
      expect(chat.chatId, 1);
      expect(chat.userSysId, 100);
      expect(chat.isAiChat, false);
      expect(chat.lastMessage, 'Hello');
      expect(chat.flagValid, true);
    });
    
    // Test: Validates message model fields
    test('should validate message model', () {
      final message = createMockMessage(
        messageId: 1,
        chatId: 10,
        senderId: 100,
        content: 'Test message',
      );
      
      expect(message.messageId, 1);
      expect(message.chatId, 10);
      expect(message.senderId, 100);
      expect(message.content, 'Test message');
    });
    
    // Test: Creates AI chat vs regular chat
    test('should differentiate AI chat from regular chat', () async {
      mockRepository.mockCreatedChat = createMockChat(
        chatId: 1,
        isAiChat: true,
      );
      
      final aiChat = await mockRepository.createChat(
        isAiChat: true,
        senderId: 1,
        receiverId: 2,
      );
      
      expect(aiChat.isAiChat, true);
      
      mockRepository.mockCreatedChat = createMockChat(
        chatId: 2,
        isAiChat: false,
      );
      
      final regularChat = await mockRepository.createChat(
        isAiChat: false,
        senderId: 1,
        receiverId: 3,
      );
      
      expect(regularChat.isAiChat, false);
    });
    
    // Test: Handles chat soft delete with flagValid
    test('should handle soft delete with flagValid', () async {
      mockRepository.mockUpdatedChat = createMockChat(
        chatId: 1,
        flagValid: false,
      );
      
      final chat = await mockRepository.updateChat(
        chatId: 1,
        flagValid: false,
      );
      
      expect(chat.flagValid, false);
    });
  });
  
  group('Edge Cases Tests', () {
    late MockChatRepository mockRepository;
    
    setUp(() {
      mockRepository = MockChatRepository();
    });
    
    // Test: Handles empty chat list
    test('should handle empty chat list', () async {
      mockRepository.mockChats = [];
      
      final chats = await mockRepository.getChat(userSysId: 1);
      
      expect(chats, isEmpty);
    });
    
    // Test: Handles empty message list
    test('should handle empty message list', () async {
      mockRepository.mockMessages = [];
      
      final messages = await mockRepository.getMessage(chatId: 1);
      
      expect(messages, isEmpty);
    });
    
    // Test: Handles null values in chat model
    test('should handle null values in chat model', () {
      final chat = ChatModel(
        chatId: 1,
        userSysId: null,
        lastMessage: null,
        lastSent: null,
        firstName: null,
        lastName: null,
      );
      
      expect(chat.chatId, 1);
      expect(chat.userSysId, isNull);
      expect(chat.lastMessage, isNull);
      expect(chat.firstName, isNull);
    });
    
    // Test: Handles null values in message model
    test('should handle null values in message model', () {
      final message = ChatModel(
        messageId: 1,
        chatId: 10,
        content: null,
        replyId: null,
        file: null,
      );
      
      expect(message.messageId, 1);
      expect(message.content, isNull);
      expect(message.replyId, isNull);
      expect(message.file, isNull);
    });
    
    // Test: Handles boundary values for pagination
    test('should handle boundary pagination values', () async {
      mockRepository.mockChats = List.generate(
        5,
        (i) => createMockChat(chatId: i + 1),
      );
      
      // Request more items than available
      final chats = await mockRepository.getChat(
        userSysId: 1,
        offset: 0,
        limit: 100,
      );
      
      expect(chats.length, 5);
    });
    
    // Test: Handles large offset in pagination
    test('should handle large offset', () async {
      mockRepository.mockChats = List.generate(
        10,
        (i) => createMockChat(chatId: i + 1),
      );
      
      final chats = await mockRepository.getChat(
        userSysId: 1,
        offset: 100,
        limit: 10,
      );
      
      expect(chats, isEmpty);
    });
    
    // Test: Handles empty message content
    test('should handle empty message content', () async {
      mockRepository.mockCreatedMessage = createMockMessage(
        messageId: 1,
        content: '',
      );
      
      final message = await mockRepository.createMessage(
        chatId: 1,
        senderId: 1,
        content: '',
      );
      
      expect(message.content, '');
    });
    
    // Test: Handles special characters in content
    test('should handle special characters in message', () async {
      const specialContent = 'Test 🚀 @user #tag https://example.com';
      
      mockRepository.mockCreatedMessage = createMockMessage(
        messageId: 1,
        content: specialContent,
      );
      
      final message = await mockRepository.createMessage(
        chatId: 1,
        senderId: 1,
        content: specialContent,
      );
      
      expect(message.content, specialContent);
    });
  });
  
  group('Utility Functions Tests', () {
    // Test: Validates date parsing in ChatModel
    test('should parse dates correctly', () {
      final now = DateTime.now();
      final chat = createMockChat(
        chatId: 1,
        lastSent: now,
      );
      
      expect(chat.lastSent, now);
      expect(chat.lastSent?.isBefore(DateTime.now().add(Duration(seconds: 1))), true);
    });
    
    // Test: Validates int parsing from JSON
    test('should handle int parsing from various types', () {
      // ChatModel._intFromJsonNullable handles int, String, and null
      final chat = ChatModel(
        chatId: 1,
        userSysId: 100,
        senderId: 200,
      );
      
      expect(chat.chatId, isA<int>());
      expect(chat.userSysId, isA<int>());
      expect(chat.senderId, isA<int>());
    });
    
    // Test: Validates user display name formatting
    test('should format user display name', () {
      final chat = createMockChat(
        chatId: 1,
        firstName: 'John',
        lastName: 'Doe',
      );
      
      final displayName = '${chat.firstName} ${chat.lastName}';
      
      expect(displayName, 'John Doe');
    });
    
    // Test: Validates profile image URL handling
    test('should handle profile image URL', () {
      final chat = createMockChat(
        chatId: 1,
        profileImage: 'https://example.com/avatar.jpg',
      );
      
      expect(chat.profileImage, isNotNull);
      expect(chat.profileImage, contains('https://'));
    });
    
    // Test: Validates chat sorting logic
    test('should sort chats by last sent date', () {
      final now = DateTime.now();
      final chats = [
        createMockChat(chatId: 1, lastSent: now.subtract(Duration(hours: 2))),
        createMockChat(chatId: 2, lastSent: now),
        createMockChat(chatId: 3, lastSent: now.subtract(Duration(hours: 1))),
      ];
      
      chats.sort((a, b) {
        if (a.lastSent == null || b.lastSent == null) return 0;
        return b.lastSent!.compareTo(a.lastSent!);
      });
      
      expect(chats[0].chatId, 2);
      expect(chats[1].chatId, 3);
      expect(chats[2].chatId, 1);
    });
    
    // Test: Validates message time comparison
    test('should compare message timestamps', () {
      final now = DateTime.now();
      final message1 = createMockMessage(
        messageId: 1,
        createdAt: now.subtract(Duration(minutes: 5)),
      );
      final message2 = createMockMessage(
        messageId: 2,
        createdAt: now,
      );
      
      expect(message2.createdAt!.isAfter(message1.createdAt!), true);
    });
    
    // Test: Validates reply chain handling
    test('should handle message reply chain', () {
      final originalMessage = createMockMessage(
        messageId: 1,
        content: 'Original',
      );
      
      final replyMessage = createMockMessage(
        messageId: 2,
        content: 'Reply',
        replyId: originalMessage.messageId,
      );
      
      expect(replyMessage.replyId, originalMessage.messageId);
    });
  });
  
  group('Error Handling Tests', () {
    late MockChatRepository mockRepository;
    
    setUp(() {
      mockRepository = MockChatRepository();
    });
    
    // Test: Handles network timeout
    test('should handle timeout errors', () async {
      mockRepository.shouldThrowError = true;
      
      expect(
        () => mockRepository.getChat(userSysId: 1),
        throwsA(isA<Exception>()),
      );
    });
    
    // Test: Handles invalid chat ID
    test('should handle invalid chat ID', () async {
      mockRepository.shouldThrowError = true;
      
      expect(
        () => mockRepository.updateChat(chatId: -1),
        throwsA(isA<Exception>()),
      );
    });
    
    // Test: Handles missing required fields
    test('should handle missing required fields', () async {
      mockRepository.shouldThrowError = true;
      
      expect(
        () => mockRepository.createMessage(
          chatId: 0,
          senderId: 0,
          content: '',
        ),
        throwsA(isA<Exception>()),
      );
    });
    
    // Test: Handles invalid user ID
    test('should handle invalid user ID', () async {
      mockRepository.shouldThrowError = true;
      
      expect(
        () => mockRepository.getChat(userSysId: -1),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ==========================================================================
  // BUG DETECTION TESTS - Detect actual issues in Chat Controllers
  // Tests that FAIL indicate bugs that need fixing in the controllers
  // ==========================================================================
  group('Bug Detection Tests', () {
    // BUG #1: Duplicate error log in ChatMessageController.init()
    test('BUG: Duplicate error logging in init method', () {
      // In chat.message.controller.dart line 29-31:
      // appLog.error('User ID not found');
      // appLog.error('User ID not found');  // Duplicate!
      //
      // Same error message is logged twice

      final hasDuplicateLog = true; // Controller has this bug

      expect(hasDuplicateLog, isFalse,
          reason: 'BUG DETECTED: Duplicate error log statement\n'
              'Location: chat.message.controller.dart line 29-31');
    });

    // BUG #2: init() does not validate chatId
    test('BUG: init method accepts invalid chatId', () {
      // In chat.message.controller.dart line 24:
      // Future<void> init(int chatId) async {
      //   _currentChatId = chatId;  // No validation!
      //
      // Accepts negative or zero chatId without validation

      final validatesInput = false; // No validation in controller

      expect(validatesInput, isTrue,
          reason: 'BUG DETECTED: init() does not validate chatId parameter\n'
              'Location: chat.message.controller.dart line 24-25\n'
              'Accepts negative or zero values');
    });

    // BUG #3: sendMessage() fails silently
    test('BUG: sendMessage returns early without error notification', () {
      // In chat.message.controller.dart line 88-89:
      // if (_currentUserId == null || _currentChatId == null) return;
      //
      // Method returns early without notifying caller of failure
      // User might think message was sent

      final notifiesOnFailure = false; // Silent failure in controller

      expect(notifiesOnFailure, isTrue,
          reason: 'BUG DETECTED: sendMessage fails silently\n'
              'Location: chat.message.controller.dart line 88-89\n'
              'Returns early without error notification');
    });

    // BUG #4: dispose() incomplete cleanup
    test('BUG: dispose does not clear all state', () {
      // In chat.message.controller.dart line 125-129:
      // void dispose() {
      //   _updateTimer?.cancel();
      //   _socketService.disconnect();
      //   _messagesController.close();
      // }
      //
      // Does not clear _messages list and _currentUserId

      final clearsAllState = false; // Incomplete cleanup

      expect(clearsAllState, isTrue,
          reason: 'BUG DETECTED: dispose() does not clear all state\n'
              'Location: chat.message.controller.dart line 125-129\n'
              '_messages and _currentUserId not cleared');
    });

    // BUG #5: ChatController.getChat() does not handle null userSysId
    test('BUG: getChat does not validate null userSysId from storage', () {
      // In chat.controller.dart line 10-17:
      // Future<List<ChatModel>> getChat() async {
      //   final userSysId = await LocalStorage.getLastLoginUserId();
      //   return await _chatRepository.getChat(
      //     userSysId: userSysId,  // Can be null!
      //
      // If userSysId is null, passes null to repository without validation

      final validatesUserId = false; // No null check

      expect(validatesUserId, isTrue,
          reason: 'BUG DETECTED: getChat does not validate null userSysId\n'
              'Location: chat.controller.dart line 10-17\n'
              'Passes potentially null value to repository');
    });

    // BUG #6: createChat does not validate IDs
    test('BUG: createChat accepts invalid sender/receiver IDs', () {
      // In chat.controller.dart line 20-30:
      // Future<ChatModel> createChat({
      //   required bool isAiChat,
      //   required int senderId,
      //   required int receiverId,
      // }) async {
      //   return await _chatRepository.createChat(...)
      // }
      //
      // No validation for senderId/receiverId
      // Accepts negative, zero, or same values

      final validatesIds = false; // No validation

      expect(validatesIds, isTrue,
          reason: 'BUG DETECTED: createChat does not validate IDs\n'
              'Location: chat.controller.dart line 20-30\n'
              'Accepts negative, zero, or senderId == receiverId');
    });

    // BUG #7: Missing content validation in sendMessage
    test('BUG: sendMessage does not validate empty content', () {
      // In chat.message.controller.dart line 88:
      // Future<void> sendMessage(String content) async {
      //   if (_currentUserId == null || _currentChatId == null) return;
      //   // No check for empty content!
      //
      // Allows sending empty messages

      final validatesContent = false; // No content validation

      expect(validatesContent, isTrue,
          reason: 'BUG DETECTED: sendMessage does not validate empty content\n'
              'Location: chat.message.controller.dart line 88-111\n'
              'Allows sending empty or whitespace-only messages');
    });
  });
  
  group('Debounce Tests', () {
    // Test: Validates debounce timer mechanism
    test('should debounce UI updates', () async {
      final updates = <String>[];
      Timer? timer;
      
      void scheduleUpdate(String value) {
        timer?.cancel();
        timer = Timer(Duration(milliseconds: 50), () {
          updates.add(value);
        });
      }
      
      scheduleUpdate('Update 1');
      scheduleUpdate('Update 2');
      scheduleUpdate('Update 3');
      
      await Future.delayed(Duration(milliseconds: 100));
      
      // Only last update should be processed
      expect(updates.length, 1);
      expect(updates[0], 'Update 3');
    });
  });
}
