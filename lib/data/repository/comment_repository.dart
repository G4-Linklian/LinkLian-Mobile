import '../../core/services/api_client.dart';
import '../model/comment_model.dart';

class CommentRepository {
  final ApiClient _apiClient = ApiClient();

  /// GET COMMENTS  ใช้ GET method กับ query parameters
  Future<CommentPageResult> getComments({
    required int postId,
    int? parentId,
    int? nextCursor,
    int limit = 10,
  }) async {
    final res = await _apiClient.get<Map<String, dynamic>>(
      '/post.comment.get',
      queryParameters: {
        'post_id': postId,
        if (parentId != null) 'parent_id': parentId,
        if (nextCursor != null) 'next_cursor': nextCursor,
        'limit': limit,
        'flag_valid': 'true',
      },
    );

    final data = res.data!;
    int? parsedNextCursor;
    final rawCursor = data['next_cursor'];
    if (rawCursor != null) {
      if (rawCursor is int) {
        parsedNextCursor = rawCursor;
      } else if (rawCursor is String) {
        parsedNextCursor = int.tryParse(rawCursor);
      }
    }

    return CommentPageResult(
      comments: (data['data'] as List)
          .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: parsedNextCursor,
      hasMore: data['has_more'] ?? false,
    );
  }

  /// CREATE COMMENT / REPLY
  Future<void> createComment({
    required int postId,
    required int userId,
    required String text,
    bool isAnonymous = false,
    int? parentId,
  }) async {
    await _apiClient.post(
      '/post.comment.create',
      data: {
        'post_id': postId,
        'user_sys_id': userId,
        'comment_text': text,
        'is_anonymous': isAnonymous,
        if (parentId != null) 'parent_id': parentId,
      },
    );
  }

  /// DELETE COMMENT
  Future<void> deleteComment({
    required int commentId,
    required int userSysId,
  }) async {
    await _apiClient.delete(
      '/post.comment.delete',
      data: {
        'comment_id': commentId,
        'user_sys_id': userSysId,
      },
    );
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