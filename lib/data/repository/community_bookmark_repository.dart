import '../../core/services/api_client.dart';

class CommunityBookmarkRepository {
  final ApiClient _apiClient = ApiClient();

  /// TOGGLE BOOKMARK
  Future<Map<String, dynamic>> toggleBookmark({required int postId}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/community/bookmark/toggle',
      data: {'post_commu_id': postId},
      requiresAuth: true,
    );

    return response.data!;
  }

  /// GET MY BOOKMARKS
  Future<List<dynamic>> getMyBookmarks() async {
    final response = await _apiClient.get<List<dynamic>>('/community/bookmark');

    return response.data ?? [];
  }

  Future<bool> checkBookmark(int postId) async {
    final res = await _apiClient.get('/community/bookmark/check/$postId');

    return res.data['bookmarked'] == true;
  }
}
