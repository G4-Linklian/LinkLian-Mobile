import 'package:LinkLian/data/model/community_post_model.dart';

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

    return response.data?['data'] ?? {};
  }

  /// GET MY BOOKMARKS
  Future<List<CommunityPostModel>> getMyBookmarks() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/community/bookmark',
    );

    final data = response.data?['data'] ?? [];

    return (data as List).map((e) => CommunityPostModel.fromJson(e)).toList();
  }

  Future<bool> checkBookmark(int postId) async {
    final res = await _apiClient.get('/community/bookmark/check/$postId');

    return res.data?['data']?['bookmarked'] == true;
  }
}
