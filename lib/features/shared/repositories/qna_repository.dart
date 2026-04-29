import 'package:LinkLian/features/shared/repositories/class_feed_repository.dart';
import '../../qna/data/models/qa_live_model.dart';
import '../../qna/data/models/qa_question_model.dart';

class QnaRepository {
  final ClassFeedRepository _repo = ClassFeedRepository();

  /// Get live detail with full context and questions
  Future<QaLive> getLiveDetail({required int qaLiveId}) async {
    try {
      final response = await _repo.getLiveDetail(qaLiveId: qaLiveId);
      return QaLive.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get live detail: $e');
    }
  }

  /// Get all files for a live session
  Future<List<Map<String, dynamic>>> getLiveFiles({
    required int sectionId,
  }) async {
    try {
      final response = await _repo.getLiveFiles(sectionId: sectionId);
      return response
          .whereType<Map<String, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to get live files: $e');
    }
  }

  /// Get questions for a live session as typed models
  Future<List<QaQuestion>> getLiveQuestions({required int qaLiveId}) async {
    try {
      final response = await _repo.getLiveQuestions(qaLiveId: qaLiveId);
      return response
          .whereType<Map<String, dynamic>>()
          .map((item) => QaQuestion.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to get live questions: $e');
    }
  }

  /// Get current log/slide state
  Future<Map<String, dynamic>> getCurrentLog({required int qaLiveId}) async {
    try {
      return await _repo.getCurrentLog(qaLiveId: qaLiveId);
    } catch (e) {
      throw Exception('Failed to get current log: $e');
    }
  }

  /// Get all logs for a live session
  Future<List<Map<String, dynamic>>> getLiveLogs({
    required int qaLiveId,
  }) async {
    try {
      final response = await _repo.getLiveLogs(qaLiveId: qaLiveId);
      return response
          .whereType<Map<String, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to get live logs: $e');
    }
  }

  /// Create a new live log entry
  Future<void> createLiveLog({
    required int qaLiveId,
    required int postId,
    required int attachmentId,
  }) async {
    try {
      await _repo.createLiveLog(
        qaLiveId: qaLiveId,
        postId: postId,
        attachmentId: attachmentId,
      );
    } catch (e) {
      throw Exception('Failed to create live log: $e');
    }
  }

  /// Send a new question
  Future<void> sendQuestion({
    required int qaLiveId,
    required String question,
    required int postId,
    required int attachmentId,
    required int askerId,
    required int slideNumber,
    bool isAnonymous = false,
  }) async {
    try {
      await _repo.sendQuestion(
        qaLiveId: qaLiveId,
        question: question,
        postId: postId,
        attachmentId: attachmentId,
        askerId: askerId,
        slideNumber: slideNumber,
        isAnonymous: isAnonymous,
      );
    } catch (e) {
      throw Exception('Failed to send question: $e');
    }
  }

  /// Upvote a question
  Future<void> upvoteQuestion({
    required int questionId,
    required int voterId,
  }) async {
    try {
      await _repo.upvoteQuestion(questionId: questionId, voterId: voterId);
    } catch (e) {
      throw Exception('Failed to upvote question: $e');
    }
  }

  /// Get live history for a section
  Future<List<QaLive>> getLiveHistory({required int sectionId}) async {
    try {
      final response = await _repo.getLiveHistory(sectionId: sectionId);
      return response
          .whereType<Map<String, dynamic>>()
          .map((item) => QaLive.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to get live history: $e');
    }
  }

  /// Get active live for a section
  Future<QaLive?> getActiveLive({required int sectionId}) async {
    try {
      final response = await _repo.getActiveLive(sectionId: sectionId);
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return QaLive.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get active live: $e');
    }
  }
}
