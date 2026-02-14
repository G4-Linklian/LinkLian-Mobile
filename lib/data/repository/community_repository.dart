import 'dart:io';
import '../../core/services/api_client.dart';
import '../model/community_model.dart';
import '../model/community_post_model.dart';

class CommunityRepository {
  final ApiClient _apiClient = ApiClient();

  /// 🔹 GET ALL COMMUNITY
  Future<List<CommunityModel>> getCommunities({String? keyword}) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/community',
        queryParameters: keyword != null && keyword.isNotEmpty
            ? {'keyword': keyword}
            : null,
      );

      if (response.data == null) {
        return [];
      }

      final communities = (response.data as List<dynamic>)
          .map((e) => CommunityModel.fromJson(e))
          .toList();

      return communities;
    } catch (e, stackTrace) {
      rethrow;
    }
  }

  /// GET COMMUNITY DETAIL
  Future<CommunityModel?> getCommunityDetail(int communityId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/community/detail/$communityId',
    );
    if (response.data == null) return null;
    return CommunityModel.fromJson(response.data!);
  }

  /// CREATE COMMUNITY
  Future<void> createCommunity({
    required String name,
    required String description,
    required List<String> rules,
    required bool isPrivate,
    required List<String> tags,
    String? imagePath,
  }) async {
    await _apiClient.uploadMultipart(
      '/community',
      files: imagePath != null ? [File(imagePath)] : [],
      fieldName: 'image',
      fields: {
        'name': name,
        'description': description,
        'is_private': isPrivate.toString(),
        for (int i = 0; i < rules.length; i++) 'rules[$i]': rules[i],
        for (int i = 0; i < tags.length; i++) 'tags[$i]': tags[i],
      },
    );
  }

  /// TOGGLE BOOKMARK
  Future<void> toggleBookmark(int postId) async {
    await _apiClient.post(
      '/community/bookmark/toggle',
      data: {'post_commu_id': postId},
    );
  }

  ///  DELETE POST
  Future<void> deletePost(int postId) async {
    await _apiClient.delete('/community/post/$postId');
  }
}
