import 'package:dio/dio.dart';
import '../../core/services/api_client.dart';
import '../model/community_comment_model.dart';

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
        'post_commu_id': postCommuId.toString(),
        'offset': offset.toString(),
        'limit': limit.toString(),
      },
    );

    final data = res.data!;

    final List<CommunityCommentModel> comments = [];
    final rawData = data['data'] as List? ?? [];

    for (final item in rawData) {
      comments.add(
        CommunityCommentModel.fromJson(item as Map<String, dynamic>),
      );
    }

    final hasMore = data['hasMore'] as bool? ?? false;

    return CommunityCommentPageResult(
      comments: comments,
      nextCursor: null,
      hasMore: hasMore,
    );
  }

  /// CREATE COMMUNITY COMMENT
  Future<Map<String, dynamic>> createComment({
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
      options: Options(headers: {'x-user-id': userId.toString()}),
    );

    return res.data ?? {};
  }

  /// UPDATE COMMUNITY COMMENT
  Future<Map<String, dynamic>> updateComment({
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

    return res.data ?? {};
  }

  /// DELETE COMMUNITY COMMENT
  Future<Map<String, dynamic>> deleteComment({
    required int commentId,
    required int userId,
  }) async {
    final res = await _apiClient.delete<Map<String, dynamic>>(
      '/community-comment',
      data: {'comment_id': commentId},
      options: Options(headers: {'x-user-id': userId.toString()}),
    );

    return res.data ?? {};
  }
}

class CommunityCommentPageResult {
  final List<CommunityCommentModel> comments;
  final int? nextCursor;
  final bool hasMore;

  CommunityCommentPageResult({
    required this.comments,
    required this.nextCursor,
    required this.hasMore,
  });
}
