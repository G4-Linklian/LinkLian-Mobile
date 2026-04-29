import 'package:LinkLian/core/utils/logger.dart';
import '../../../core/services/api_client.dart';
import '../../../core/utils/api_response_parser.dart';

import '../../classes/data/models/class_feed_model.dart';
import '../../auth/controller/auth_controller.dart';
import '../models/class_info_model.dart';
import '../models/section_educator_model.dart';

import 'package:get/get.dart';

class ClassFeedRepository {
  final ApiClient _apiClient = ApiClient();

  /// =========================
  /// CLASS FEED
  /// =========================
  Future<List<ClassFeedModel>> getClassFeed({
    required int semesterId,
    int offset = 0,
    int limit = 10,
  }) async {
    final auth = Get.find<AuthController>();

    final userId = auth.userId.value;
    final roleName = auth.roleName.value;

    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final isTeacher = roleName == 'teacher' || roleName == 'instructor';

    final endpoint = isTeacher
        ? '/social-feed/feed/teacher'
        : '/social-feed/feed/student';

    final response = await _apiClient.get<Map<String, dynamic>>(
      endpoint,
      queryParameters: {
        'user_id': userId,
        'semester_id': semesterId,
        'offset': offset,
        'limit': limit,
      },
    );

    return ApiResponseParser.parseList(response.data, ClassFeedModel.fromJson);
  }

  /// =========================
  /// CLASS DETAIL
  /// =========================
  Future<ClassFeedModel?> getClassDetail({required int sectionId}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/social-feed/post',
        queryParameters: {'section_id': sectionId},
      );

      final list = ApiResponseParser.parseList(
        response.data,
        ClassFeedModel.fromJson,
      );

      if (list.isEmpty) return null;

      return list.first;
    } catch (e) {
      appLog.error(
        'Error fetching class detail',
        actionPage: 'ClassFeedRepository',
        exception: e,
      );
      return null;
    }
  }

  /// =========================
  /// CLASS DETAIL FEED
  /// =========================
  Future<List<ClassFeedModel>> getClassDetailFeed({
    required int sectionId,
    String? postType,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/social-feed/post',
      queryParameters: {
        'section_id': sectionId,
        if (postType != null) 'type': postType,
      },
    );

    return ApiResponseParser.parseList(response.data, ClassFeedModel.fromJson);
  }

  /// =========================
  /// SECTION EDUCATORS
  /// =========================
  Future<List<SectionEducatorModel>> getSectionEducators({
    required int sectionId,
  }) async {
    final response = await _apiClient.get<dynamic>(
      '/social-feed/section-educators/$sectionId',
    );

    return ApiResponseParser.parseList(
      response.data,
      SectionEducatorModel.fromJson,
    );
  }

  /// =========================
  /// CLASS INFO
  /// =========================
  Future<ClassInfoModel?> getClassInfo({required int sectionId}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/social-feed/class-info/$sectionId',
    );

    return ApiResponseParser.parseObject(
      response.data,
      ClassInfoModel.fromJson,
    );
  }

  Future<Map<String, dynamic>> getActiveLive({required int sectionId}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/qa/live/section/$sectionId/active-live',
    );

    return response.data ?? {};
  }

  Future<Map<String, dynamic>> getLiveDetail({required int qaLiveId}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/qa/live/$qaLiveId',
    );

    final data = response.data;

    if (data == null) return {};

    return data['data'] ?? {};
  }

  Future<List<dynamic>> getLiveFiles({required int sectionId}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/qa/live/section/$sectionId/files',
      queryParameters: {
        // Backend requires at least one search field for this endpoint.
        'flag_valid': true,
      },
    );

    return response.data?['data'] ?? [];
  }

  Future<List<dynamic>> getLiveQuestions({required int qaLiveId}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/qa/question',
      queryParameters: {
        'qa_live_id': qaLiveId,
        // Force DB-backed query path on backend (skip list-cache-only path).
        'flag_valid': true,
      },
    );

    return response.data?['data'] ?? [];
  }

  Future<Map<String, dynamic>> getCurrentLog({required int qaLiveId}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/qa/live/$qaLiveId/current-log',
    );

    return response.data?['data'] ?? {};
  }

  Future<List<dynamic>> getLiveLogs({required int qaLiveId}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/qa/live/log',
      queryParameters: {
        'qa_live_id': qaLiveId,
        'flag_valid': true,
        'sort_by': 'opened_at',
        'sort_order': 'ASC',
      },
    );

    return response.data?['data'] ?? [];
  }

  Future<void> createLiveLog({
    required int qaLiveId,
    required int postId,
    required int attachmentId,
  }) async {
    await _apiClient.post(
      '/qa/live/log',
      data: {
        'qa_live_id': qaLiveId,
        'post_id': postId,
        'attachment_id': attachmentId,
      },
    );
  }

  Future<void> sendQuestion({
    required int qaLiveId,
    required String question,
    required int postId,
    required int attachmentId,
    required int askerId,
    required int slideNumber,
    bool isAnonymous = false,
  }) async {
    await _apiClient.post(
      '/qa/question',
      data: {
        'qa_live_id': qaLiveId,
        'asker_id': askerId,
        'is_anonymous': isAnonymous,
        'question': question,
        'post_id': postId,
        'attachment_id': attachmentId,
        'slide_number': slideNumber,
      },
    );
  }

  Future<void> upvoteQuestion({
    required int questionId,
    required int voterId,
  }) async {
    await _apiClient.post(
      '/qa/upvote',
      data: {'qa_question_id': questionId, 'voter_id': voterId},
    );
  }

  Future<List<dynamic>> getLiveHistory({required int sectionId}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/qa/live',
      queryParameters: {'section_id': sectionId},
    );

    return response.data?['data'] ?? [];
  }
}
