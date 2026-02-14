import 'dart:io';

import '../../core/services/api_client.dart';
import '../model/community_post_model.dart';

class CommunityPostRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> createPost({
    required int communityId,
    required String content,
    List<File>? files,
  }) async {
    final response = await _apiClient.uploadMultipart(
      '/community/post',
      files: files ?? [],
      fieldName: 'files',
      fields: {'community_id': communityId, 'content': content},
    );

    return response.data as Map<String, dynamic>;
  }

  Future<List<CommunityPostModel>> getCommunityFeed({
    required int communityId,
    int limit = 20,
    int offset = 0,
    String sort = 'newest',
  }) async {
    final response = await _apiClient.get<dynamic>(
      '/community/post/$communityId',
      queryParameters: {'limit': limit, 'offset': offset,'sort': sort, },
    );

    final raw = response.data;

    print("RAW RESPONSE: $raw");

    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map((e) => CommunityPostModel.fromJson(e))
          .toList();
    }

    if (raw is Map<String, dynamic> && raw['data'] is List) {
      return (raw['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => CommunityPostModel.fromJson(e))
          .toList();
    }

    return [];
  }

  Future<void> deletePost({required int postId}) async {
    await _apiClient.delete('/community/post/$postId');
  }
}
