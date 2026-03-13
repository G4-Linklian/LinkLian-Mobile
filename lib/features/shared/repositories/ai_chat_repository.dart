import 'package:LinkLian/core/services/api_client.dart';

class AIChatRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> generateSummary(int postContentId) async {
    final response = await _apiClient.post(
      '/ai-chat/summary',
      data: {"post_content_id": postContentId},
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return response.data["data"] ?? response.data;
    }

    throw Exception("Failed to generate summary");
  }

  Future<Map<String, dynamic>> generateQuiz({
    required int aiChatId,
    required String difficulty,
    required int questionCount,
  }) async {
    final response = await _apiClient.post(
      '/quiz',
      data: {
        "ai_chat_id": aiChatId,
        "difficulty": difficulty,
        "question_count": questionCount,
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return response.data["data"] ?? response.data;
    }

    throw Exception("Failed to generate quiz");
  }

  Future<List<Map<String, dynamic>>> getAIChats() async {
    final response = await _apiClient.get('/ai-chat');

    if (response.statusCode == 200) {
      final data = response.data["data"] ?? response.data;
      return List<Map<String, dynamic>>.from(data);
    }

    throw Exception("Failed to load AI chats");
  }
}
