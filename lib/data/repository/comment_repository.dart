import 'package:dio/dio.dart';
import '../../core/services/api_client.dart';
import '../model/comment_model.dart';

class CommentRepository {
  final ApiClient _apiClient = ApiClient();

  /// GET COMMENTS - Fetches comment tree for a post with pagination
  Future<CommentPageResult> getComments({
    required int postId,
    int offset = 0,
    int limit = 10,
  }) async {
    final res = await _apiClient.get<Map<String, dynamic>>(
      '/post-comment',
      queryParameters: {
        'post_id': postId.toString(),
        'offset': offset.toString(),
        'limit': limit.toString(),
      },
    );

    final data = res.data!;
    
    // Backend returns nested tree structure
    final List<CommentModel> comments = [];
    final rawData = data['data'] as List? ?? [];
    
    for (final item in rawData) {
      comments.add(CommentModel.fromJson(item as Map<String, dynamic>));
    }

    final hasMore = data['hasMore'] as bool? ?? false;

    return CommentPageResult(
      comments: comments,
      nextCursor: null,
      hasMore: hasMore,
    );
  }

  /// CREATE COMMENT / REPLY
  Future<Map<String, dynamic>> createComment({
    required int postId,
    required int userId,
    required String text,
    bool isAnonymous = false,
    int? parentId,
  }) async {
    final res = await _apiClient.post<Map<String, dynamic>>(
      '/post-comment',
      data: {
        'post_id': postId,
        'comment_text': text,
        'is_anonymous': isAnonymous,
        if (parentId != null) 'parent_id': parentId,
      },
      options: Options(headers: {'x-user-id': userId.toString()}),
    );

    return res.data ?? {};
  }

  /// UPDATE COMMENT
  Future<Map<String, dynamic>> updateComment({
    required int commentId,
    required int userId,
    String? commentText,
    bool? flagValid,
  }) async {
    final res = await _apiClient.put<Map<String, dynamic>>(
      '/post-comment',
      data: {
        'comment_id': commentId,
        if (commentText != null) 'comment_text': commentText,
        if (flagValid != null) 'flag_valid': flagValid,
      },
      options: Options(headers: {'x-user-id': userId.toString()}),
    );

    return res.data ?? {};
  }

  /// DELETE COMMENT (soft delete)
  Future<Map<String, dynamic>> deleteComment({
    required int commentId,
    required int userSysId,
  }) async {
    final res = await _apiClient.delete<Map<String, dynamic>>(
      '/post-comment',
      data: {
        'comment_id': commentId,
      },
      options: Options(headers: {'x-user-id': userSysId.toString()}),
    );

    return res.data ?? {};
  }
}

/// ===== Pagination wrapper =====
class CommentPageResult {
  final List<CommentModel> comments;
  final int? nextCursor;
  final bool hasMore;

  CommentPageResult({
    required this.comments,
    required this.nextCursor,
    required this.hasMore,
  });
}