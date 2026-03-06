import 'package:LinkLian/core/utils/api_response_parser.dart';
import 'package:LinkLian/features/community/data/models/community_comment_page_result.dart';
import 'package:dio/dio.dart';
import '../../../../core/services/api_client.dart';
import '../models/community_comment_model.dart';

class CommunityCommentRepository {
  final ApiClient _apiClient = ApiClient();

  /// GET COMMUNITY COMMENTS
  Future<CommunityCommentPageResult> getComments({
    required int postCommuId,
    int offset = 0,
    int limit = 10,
  }) async {
    final res = await _apiClient.get<Map<String, dynamic>>(
      '/community-comment',
      queryParameters: {
        'post_commu_id': postCommuId,
        'offset': offset,
        'limit': limit,
      },
    );
    final comments = ApiResponseParser.parseList(
      res.data?['data']?['comments'],
      CommunityCommentModel.fromJson,
    );

    final data = ApiResponseParser.parseObject(res.data, (json) => json) ?? {};
    final hasMore = data['hasMore'] == true;

    return CommunityCommentPageResult(
      comments: comments,
      nextCursor: null,
      hasMore: hasMore,
    );
  }

  /// CREATE COMMUNITY COMMENT
  Future<int> createComment({
    required int postCommuId,
    required int userId,
    required String text,
    int? parentId,
  }) async {
    final res = await _apiClient.post<Map<String, dynamic>>(
      '/community-comment',
      data: {
        'post_commu_id': postCommuId,
        'comment_text': text,
        if (parentId != null) 'parent_id': parentId,
      },
    );

    final data = ApiResponseParser.parseObject(res.data, (json) => json);

    if (data == null) {
      throw Exception('Invalid response structure');
    }

    final commentId = data['comment_id'];
    if (commentId == null) {
      throw Exception('comment_id not found');
    }

    return int.parse(commentId.toString());
  }

  /// UPDATE COMMUNITY COMMENT
  Future<bool> updateComment({
    required int commentId,
    required int userId,
    String? commentText,
  }) async {
    final res = await _apiClient.put<Map<String, dynamic>>(
      '/community-comment',
      data: {
        'comment_id': commentId,
        if (commentText != null) 'comment_text': commentText,
      },
      options: Options(headers: {'x-user-id': userId.toString()}),
    );

    final success = ApiResponseParser.parseSuccess(res.data);

    if (!success) {
      throw Exception('Failed to update comment');
    }

    return true;
  }

  /// DELETE COMMUNITY COMMENT
  Future<bool> deleteComment({
    required int commentId,
    required int userId,
  }) async {
    final res = await _apiClient.delete<Map<String, dynamic>>(
      '/community-comment',
      data: {'comment_id': commentId},
      options: Options(headers: {'x-user-id': userId.toString()}),
    );
    final success = ApiResponseParser.parseSuccess(res.data);

    if (!success) {
      throw Exception('Failed to delete comment');
    }

    return true;
  }
}
