import 'package:LinkLian/core/services/api_client.dart';
import 'package:dio/dio.dart';

class AIChatRepository {
  final ApiClient _apiClient = ApiClient();

  Map<String, dynamic> _mergeQuizPayload(Map<String, dynamic> source) {
    final merged = <String, dynamic>{};

    merged['quiz_title'] = source['quiz_title'];

    merged.addAll(source);

    final quizDetail = source['quiz_detail'];

    if (quizDetail is Map) {
      final quizDetailMap = Map<String, dynamic>.from(quizDetail);
      final result = quizDetailMap['result'];

      if (result is Map) {
        merged.addAll(Map<String, dynamic>.from(result));
      }
    }

    return merged;
  }

  Future<Map<String, dynamic>> generateSummary(int postContentId) async {
    final response = await _apiClient.post(
      '/ai-chat',
      data: {"post_content_id": postContentId},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(response.data);
    }

    throw Exception("Failed to generate summary");
  }

  Future<Map<String, dynamic>> generateQuiz({
    required int aiChatId,
    required String difficulty,
    required int questionCount,
    required String mode,
  }) async {
    Future<Map<String, dynamic>> sendRequest() async {
      final response = await _apiClient.post(
        '/quiz',
        data: {
          "ai_chat_id": aiChatId,
          "difficulty": difficulty,
          "question_count": questionCount,
          "mode": mode,
          "title": mode == "learning" ? "แบบการเรียนรู้" : "แบบทดสอบ",
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = Map<String, dynamic>.from(response.data);
        return _mergeQuizPayload(data);
      }

      throw Exception("Failed to generate quiz");
    }

    try {
      return await sendRequest();
    } on DioException catch (e) {
      final shouldRetry =
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout;

      if (!shouldRetry) rethrow;

      await Future.delayed(const Duration(milliseconds: 500));
      return await sendRequest();
    }
  }

  Future<List<Map<String, dynamic>>> getAIChats() async {
    final response = await _apiClient.get('/ai-chat');

    if (response.statusCode == 200) {
      final List data = response.data;

      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    }

    throw Exception("Failed to load AI chats");
  }

  Future<Map<String, dynamic>> getAIChat(int id) async {
    final response = await _apiClient.get('/ai-chat/$id');

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(response.data);
    }

    throw Exception("Failed to load AI chat detail");
  }

  Future<List<Map<String, dynamic>>> getQuiz(int aiChatId) async {
    final response = await _apiClient.get('/quiz/by-chat/$aiChatId');

    if (response.statusCode == 200) {
      final List data = response.data;

      return data.map((item) {
        return _mergeQuizPayload(Map<String, dynamic>.from(item));
      }).toList();
    }

    return [];
  }

  Future<void> saveQuizAttempt({
    required int quizId,
    required int score,
    required int total,
    required Map<int, String> answers,
  }) async {
    final formattedAnswers = answers.map(
      (key, value) => MapEntry(key.toString(), value),
    );

    await _apiClient.post(
      '/quiz/attempt',
      data: {
        "quiz_id": quizId,
        "score": score,
        "total": total,
        "answers": formattedAnswers,
      },
    );
  }

  Future<Map<String, dynamic>?> getQuizAttempt(int quizId) async {
    final response = await _apiClient.get('/quiz/attempt/$quizId');

    if (response.statusCode == 200 && response.data is Map) {
      return Map<String, dynamic>.from(response.data);
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> getMessages(int aiChatId) async {
    final response = await _apiClient.get(
      '/ai-chat/messages?ai_chat_id=$aiChatId',
    );

    if (response.statusCode == 200) {
      final List data = response.data["data"] ?? response.data;

      return data.map((item) {
        return Map<String, dynamic>.from(item);
      }).toList();
    }

    throw Exception("Failed to load messages");
  }

  Future<Map<String, dynamic>> sendMessage({
    required int aiChatId,
    required String question,
    required int postContentId,
  }) async {
    final response = await _apiClient.post(
      '/ai-chat/messages',
      data: {
        "ai_chat_id": aiChatId,
        "question": question,
        "post_content_id": postContentId,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(response.data);
    }

    throw Exception("Failed to send message");
  }

  Future<Map<String, dynamic>> checkAnswer({
    required int quizId,
    required int questionIndex,
    required String selected,
  }) async {
    final response = await _apiClient.post(
      '/quiz/check-answer',
      data: {
        "quiz_id": quizId,
        "question_index": questionIndex,
        "selected": selected,
      },
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(response.data);
    }

    throw Exception("Failed to check answer");
  }
}
