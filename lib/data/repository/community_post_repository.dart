import 'dart:convert';
import 'dart:io';

import 'package:LinkLian/data/model/community_attachment_model.dart';

import '../../core/services/api_client.dart';
import '../model/community_post_model.dart';

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

    final root = response.data ?? {};

    if (root['success'] != true) {
      throw Exception(root['message'] ?? 'Create post failed');
    }

    return root['data'] ?? {};
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

    final root = response.data ?? {};

    if (root['success'] != true) {
      throw Exception(root['message'] ?? 'Fetch posts failed');
    }
    final List rawPosts = root['data']?['posts'] ?? [];

    return rawPosts
        .whereType<Map<String, dynamic>>()
        .map((e) => CommunityPostModel.fromJson(e))
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

  final root = response.data ?? {};

  if (root['success'] != true) {
    throw Exception(root['message'] ?? 'Update failed');
  }

 final data = root['data'];

if (data == null) {
  throw Exception("Backend did not return updated post data");
}

return CommunityPostModel.fromJson(data);
}

  Future<bool> deletePost({required int postId}) async {
    final res = await _apiClient.delete<Map<String, dynamic>>(
       '/community/post/$postId/hard',
    );

    final root = res.data ?? {};

    if (root['success'] != true) {
      throw Exception(root['message'] ?? 'Delete failed');
    }

    return true;
  }
}
