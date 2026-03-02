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
        'post_commu_id': postCommuId,
        'offset': offset,
        'limit': limit,
      },
    );
    final root = res.data ?? {};
    if (root['success'] != true) {
      throw Exception(root['message'] ?? 'Failed to fetch comments');
    }
    final Map<String, dynamic> data =
        (root['data'] as Map<String, dynamic>?) ?? {};

    final List<dynamic> rawComments =
        (data['comments'] as List<dynamic>?) ?? [];

    final comments = rawComments
        .map((e) => CommunityCommentModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final bool hasMore = data['hasMore'] == true;

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

    final root = res.data ?? {};

    if (root['success'] != true) {
      throw Exception(root['message'] ?? 'Failed to create comment');
    }
    final data = root['data'] as Map<String, dynamic>?;

    if (data == null || data['comment_id'] == null) {
      throw Exception('Invalid response structure');
    }

    return int.parse(data['comment_id'].toString());
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

    final root = res.data ?? {};

    if (root['success'] != true) {
      throw Exception(root['message'] ?? 'Failed to update comment');
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

    final root = res.data ?? {};

    if (root['success'] != true) {
      throw Exception(root['message'] ?? 'Failed to delete comment');
    }

    return true;
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
