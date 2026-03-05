import 'dart:io';
import '../../core/services/api_client.dart';
import '../model/community_model.dart';
import 'dart:convert';

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
        'rules': jsonEncode(rules),
        'tags': jsonEncode(tags),
      },
    );
    final root = response.data ?? {};

    if (root['success'] != true) {
      throw Exception(root['message'] ?? 'Create failed');
    }
  }

  Future<void> updateCommunity({
    required int communityId,
    required String name,
    required String description,
    required bool isPrivate,
    required List<String> rules,
    required List<String> tags,
    String? imagePath,
  }) async {
    final response = await _apiClient.uploadMultipart(
      '/community/$communityId',
      method: 'PUT',
      files: imagePath != null ? [File(imagePath)] : [],
      fieldName: 'image',
      fields: {
        'name': name,
        'description': description,
        'is_private': isPrivate.toString(),
        'rules': jsonEncode(rules),
        'tags': jsonEncode(tags),
      },
    );

    final root = response.data ?? {};

    if (root['success'] != true) {
      throw Exception(root['message'] ?? 'Update failed');
    }
  }

  Future<void> deleteCommunity(int communityId) async {
    final res = await _apiClient.delete<Map<String, dynamic>>(
      '/community/$communityId/hard',
    );

    final root = res.data ?? {};

    if (root['success'] != true) {
      throw Exception(root['message'] ?? 'Delete community failed');
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
