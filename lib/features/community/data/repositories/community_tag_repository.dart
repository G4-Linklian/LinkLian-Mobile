import 'package:LinkLian/core/utils/api_response_parser.dart';

import '../../../../core/services/api_client.dart';
import '../models/community_tag_model.dart';

class CommunityTagRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<CommunityTagModel>> searchTag({required String keyword}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/community/tag/search',
      queryParameters: {'keyword': keyword},
    );

    final Map<String, dynamic> data =
        ApiResponseParser.parseObject<Map<String, dynamic>>(
          response.data,
          (json) => json,
        ) ??
        {};

    final rawTags = (data['tags'] as List?) ?? [];

    return rawTags
        .whereType<Map<String, dynamic>>()
        .map(CommunityTagModel.fromJson)
        .toList();
  }
}
