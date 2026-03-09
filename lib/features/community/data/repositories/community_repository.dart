import 'dart:io';
import 'package:LinkLian/core/utils/api_response_parser.dart';

import '../../../../core/services/api_client.dart';
import '../models/community_model.dart';
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

    return ApiResponseParser.parseList(
      response.data?['data']?['communities'],
      CommunityModel.fromJson,
    );
  }

  /// GET COMMUNITY DETAIL
  Future<CommunityModel?> getCommunityDetail(int communityId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/community/detail/$communityId',
    );
    final data = ApiResponseParser.parseObject(
      response.data,
      CommunityModel.fromJson,
    );

    return data;
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
    if (!ApiResponseParser.parseSuccess(response.data)) {
      throw Exception('Create failed');
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

    if (!ApiResponseParser.parseSuccess(response.data)) {
      throw Exception('Update failed');
    }
  }

  Future<void> deleteCommunity(int communityId) async {
    final res = await _apiClient.delete<Map<String, dynamic>>(
      '/community/$communityId/hard',
    );

    if (!ApiResponseParser.parseSuccess(res.data)) {
      throw Exception('Delete community failed');
    }
  }

  /// TOGGLE BOOKMARK
  Future<void> toggleBookmark(int postId) async {
    final res = await _apiClient.post<Map<String, dynamic>>(
      '/community/bookmark/toggle',
      data: {'post_commu_id': postId},
    );
    if (!ApiResponseParser.parseSuccess(res.data)) {
      throw Exception('Toggle failed');
    }
  }

  ///  DELETE POST
  Future<void> deletePost(int postId) async {
    final res = await _apiClient.delete<Map<String, dynamic>>(
      '/community/post/$postId',
    );

    if (!ApiResponseParser.parseSuccess(res.data)) {
      throw Exception('Delete failed');
    }
  }
}
