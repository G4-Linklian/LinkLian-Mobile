import '../../core/services/api_client.dart';
import '../model/community_tag_model.dart';

class CommunityTagRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<CommunityTagModel>> searchTag({required String keyword}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/community/tag/search',
      queryParameters: {'keyword': keyword},
    );

    final root = response.data ?? {};

    if (root['success'] != true) {
      throw Exception(root['message'] ?? 'Search tag failed');
    }

    final List rawTags = root['data']?['tags'] ?? [];

    return rawTags
        .whereType<Map<String, dynamic>>()
        .map((e) => CommunityTagModel.fromJson(e))
        .toList();
  }
}
