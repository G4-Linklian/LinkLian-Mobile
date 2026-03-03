import 'dart:io';
import '../../core/services/api_client.dart';
import '../model/community_model.dart';

class CommunityRepository {
  final ApiClient _apiClient = ApiClient();

  /// GET ALL COMMUNITY
  Future<List<CommunityModel>> getCommunities({String? keyword}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/community',
      queryParameters: keyword != null && keyword.isNotEmpty
          ? {'keyword': keyword}
          : null,
    );

    final root = response.data ?? {};

    if (root['success'] != true) {
      throw Exception(root['message'] ?? 'Fetch communities failed');
    }

    final List raw = root['data']?['communities'] ?? [];

    return raw
        .whereType<Map<String, dynamic>>()
        .map((e) => CommunityModel.fromJson(e))
        .toList();
  }

  /// GET COMMUNITY DETAIL
  Future<CommunityModel?> getCommunityDetail(int communityId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/community/detail/$communityId',
    );
    final root = response.data ?? {};

    if (root['success'] != true) {
      throw Exception(root['message'] ?? 'Fetch detail failed');
    }

    final data = root['data'];
    if (data == null) return null;
    return CommunityModel.fromJson(data);
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
    final response = await _apiClient.uploadMultipart(
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
    final root = response.data ?? {};

    if (root['success'] != true) {
      throw Exception(root['message'] ?? 'Create failed');
    }
  }

  /// TOGGLE BOOKMARK
  Future<void> toggleBookmark(int postId) async {
    final res = await _apiClient.post<Map<String, dynamic>>(
      '/community/bookmark/toggle',
      data: {'post_commu_id': postId},
    );
    final root = res.data ?? {};

    if (root['success'] != true) {
      throw Exception(root['message'] ?? 'Toggle failed');
    }
  }

  ///  DELETE POST
  Future<void> deletePost(int postId) async {
    final res = await _apiClient.delete<Map<String, dynamic>>(
      '/community/post/$postId',
    );

    final root = res.data ?? {};

    if (root['success'] != true) {
      throw Exception(root['message'] ?? 'Delete failed');
    }
  }
}
