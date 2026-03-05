import 'dart:convert';
import 'dart:io';

import 'package:LinkLian/core/utils/api_response_parser.dart';
import 'package:LinkLian/features/community/data/models/community_attachment_model.dart';

import '../../../../core/services/api_client.dart';
import '../models/community_post_model.dart';

class CommunityPostRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> createPost({
    required int communityId,
    required String content,
    List<File>? files,
  }) async {
    final fields = {'community_id': communityId, 'content': content};

    final response = await _apiClient.uploadMultipart(
      '/community/post',
      files: files ?? [],
      fieldName: 'files',
      fields: fields,
    );

    final data = ApiResponseParser.parseObject<Map<String, dynamic>>(
      response.data,
      (json) => json,
    );

    return data ?? {};
  }

  Future<List<CommunityPostModel>> getCommunityFeed({
    required int communityId,
    int limit = 20,
    int offset = 0,
    String sort = 'newest',
  }) async {
    final response = await _apiClient.get<dynamic>(
      '/community/post/$communityId',
      queryParameters: {'limit': limit, 'offset': offset, 'sort': sort},
    );

    final data =
        ApiResponseParser.parseObject<Map<String, dynamic>>(
          response.data,
          (json) => json,
        ) ??
        {};

    final rawPosts = (data['posts'] as List?) ?? [];

    return rawPosts
        .whereType<Map<String, dynamic>>()
        .map(CommunityPostModel.fromJson)
        .toList();
  }

  Future<CommunityPostModel> updatePost({
    required int postId,
    required String content,
    List<File>? files,
    List<CommunityAttachmentModel>? keepAttachments,
  }) async {
    final fields = {
      'content': content,
      'keep_attachments': jsonEncode(
        keepAttachments?.map((e) => e.toJson()).toList() ?? [],
      ),
    };

    final response = await _apiClient.uploadMultipart(
      '/community/post/$postId',
      method: 'PUT',
      files: files ?? [],
      fieldName: 'files',
      fields: fields,
    );

    final data = ApiResponseParser.parseObject<Map<String, dynamic>>(
      response.data,
      (json) => json,
    );

    if (data == null) {
      throw Exception("Backend did not return updated post data");
    }

    return CommunityPostModel.fromJson(data);
  }

  Future<bool> deletePost({required int postId}) async {
    final res = await _apiClient.delete<Map<String, dynamic>>(
      '/community/post/$postId/hard',
    );

    final data = ApiResponseParser.parseObject<Map<String, dynamic>>(
      res.data,
      (json) => json,
    );

    if (data == null) {
      throw Exception('Delete failed');
    }

    return true;
  }
}
