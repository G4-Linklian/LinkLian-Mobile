import '../../core/services/api_client.dart';
import '../model/community_tag_model.dart';

class CommunityTagRepository {
  final ApiClient _apiClient = ApiClient();

 Future<List<CommunityTagModel>> searchTag({required String keyword}) async {
    final response = await _apiClient.get<List<dynamic>>(
      '/community/tag/search',
      queryParameters: {'keyword': keyword},
    );

    final data = response.data ?? [];
    return data.map((e) => CommunityTagModel.fromJson(e)).toList();
  }
}
