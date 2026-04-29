import '../../../core/services/api_client.dart';
import '../../../core/utils/api_response_parser.dart';
import '../../classes/data/models/bookmark_model.dart';

class BookmarkRepository {
  final ApiClient api;

  BookmarkRepository(this.api);

  /// Get bookmarks with filters (similar to old POST /bookmark.get)
  Future<List<BookmarkModel>> getBookmarks({
    required int userId,
    int? postId,
    int? sectionId,
    bool flagValid = true,
    int offset = 0,
    int limit = 50,
    String sortBy = 'saved_at',
    String? sortOrder,
  }) async {
    final response = await api.get<Map<String, dynamic>>(
      '/bookmarks',
      queryParameters: {
        'user_sys_id': userId,
        if (postId != null) 'post_id': postId,
        if (sectionId != null) 'section_id': sectionId,
        'flag_valid': flagValid,
        'offset': offset,
        'limit': limit,
        'sort_by': sortBy,
        if (sortOrder != null) 'sort_order': sortOrder,
      },
    );

    final data = response.data;
    if (data == null || data['success'] != true) {
      throw Exception(data?['message'] ?? 'Failed to fetch bookmarks');
    }

    return ApiResponseParser.parseList(data, BookmarkModel.fromJson);
  }

  /// Toggle bookmark (create if not exists, delete if exists)
  Future<bool> toggleBookmark({
    required int userId,
    required int postId,
  }) async {
    final response = await api.post<Map<String, dynamic>>(
      '/bookmarks/toggle',
      data: {'user_sys_id': userId, 'post_id': postId},
    );

    final data = response.data;

    if (data == null) {
      throw Exception('Invalid response');
    }

    return data['success'] == true;
  }

  /// Delete bookmark
  Future<bool> deleteBookmark({
    required int userId,
    required int postId,
  }) async {
    final response = await api.delete<Map<String, dynamic>>(
      '/bookmarks',
      data: {'user_sys_id': userId, 'post_id': postId},
    );

    final data = response.data;

    return data?['success'] == true;
  }
}
