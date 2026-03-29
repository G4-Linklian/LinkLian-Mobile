import 'package:LinkLian/core/utils/api_response_parser.dart';
import 'package:LinkLian/features/community/data/models/community_post_model.dart';

import '../../../../core/services/api_client.dart';

class CommunityBookmarkRepository {
  final ApiClient _apiClient = ApiClient();

  /// TOGGLE BOOKMARK
  Future<Map<String, dynamic>> toggleBookmark({required int postId}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/community/bookmark/toggle',
      data: {'post_commu_id': postId},
      requiresAuth: true,
    );

    final data = ApiResponseParser.parseObject<Map<String, dynamic>>(
      response.data,
      (json) => json,
    );

    return data ?? {};
  }

  /// GET MY BOOKMARKS
  Future<List<CommunityPostModel>> getMyBookmarks() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/community/bookmark',
    );

    return ApiResponseParser.parseList(
      response.data?['data'],
      CommunityPostModel.fromJson,
    );
  }

  Future<bool> checkBookmark(int postId) async {
    final res = await _apiClient.get('/community/bookmark/check/$postId');

    final data = ApiResponseParser.parseObject(res.data, (json) => json);

    return data?['bookmarked'] == true;
  }
}
