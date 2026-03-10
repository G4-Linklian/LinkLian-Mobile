import 'package:LinkLian/core/utils/logger.dart';
import 'package:LinkLian/features/shared/models/post_model.dart';
import 'package:flutter/foundation.dart';
import '../../core/services/api_client.dart';
import 'dart:io';

class PostRepository {
  final ApiClient _apiClient = ApiClient();

  /// CREATE POST (supports multiple section_ids)
  Future<Map<String, dynamic>> createPost({
    int? sectionId,
    List<int>? sectionIds,
    String? title,
    String? content,
    String? postType,
    bool isAnonymous = false,
    List<Map<String, dynamic>>? attachments,
    // Assignment-specific fields
    String? dueDate,
    double? maxScore,
    bool? isGroup,
    List<Map<String, dynamic>>? groups, // {group_name, member_ids}
  }) async {
    // Build payload - support both single and multiple sections
    final Map<String, dynamic> data = {
      if (title != null && title.isNotEmpty) 'title': title,
      if (content != null && content.isNotEmpty) 'content': content,
      if (postType != null && postType.isNotEmpty) 'post_type': postType,
      'is_anonymous': isAnonymous,
    };

    // Add attachments only if not empty
    if (attachments != null && attachments.isNotEmpty) {
      final validAttachments = attachments
          .where(
            (a) =>
                a['file_url'] != null &&
                a['file_url'].toString().isNotEmpty &&
                a['file_type'] != null &&
                a['file_type'].toString().isNotEmpty,
          )
          .map(
            (a) => {
              'file_url': a['file_url'],
              'file_type': a['file_type'],
              if (a['original_name'] != null)
                'original_name': a['original_name'],
            },
          )
          .toList();

      if (validAttachments.isNotEmpty) {
        data['attachments'] = validAttachments;
      }
    }

    // Prefer section_ids over section_id
    if (sectionIds != null && sectionIds.isNotEmpty) {
      data['section_ids'] = sectionIds;
    } else if (sectionId != null) {
      data['section_id'] = sectionId;
    }

    // Add assignment-specific fields if post_type is 'assignment'
    if (postType == 'assignment') {
      if (dueDate != null) data['due_date'] = dueDate;
      if (maxScore != null) data['max_score'] = maxScore;
      if (isGroup != null) data['is_group'] = isGroup;
      if (groups != null && groups.isNotEmpty) data['groups'] = groups;
    }

    debugPrint('📤 Creating post with data: $data');

    final response = await _apiClient.post<dynamic>(
      '/social-feed/post',
      data: data,
    );

    debugPrint('📥 Create post response: ${response.data}');

    // Handle response - it may be Map or nested
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }

    return {'success': true, 'data': response.data};
  }

  /// GET POSTS IN CLASS
  Future<List<PostModel>> getPostInClass({
    required int sectionId,
    String? filterType,
    int offset = 0,
    int limit = 10,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/social-feed/post',
      queryParameters: {
        'section_id': sectionId,
        if (filterType != null && filterType.isNotEmpty) 'type': filterType,
        'offset': offset,
        'limit': limit,
      },
    );

    appLog.debug('GET POST RESPONSE RAW: ${response.data.runtimeType}');

    final rawList =
        (response.data as Map<String, dynamic>)['data'] as List? ?? [];

    return rawList
        .map<PostModel>((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// UPDATE POST (by post_content_id)
  Future<Map<String, dynamic>> updatePost({
    int? postId,
    required int postContentId,
    String? title,
    String? content,
    List<Map<String, dynamic>>? attachments,
    String? dueDate,
    double? maxScore,
    bool? isGroup,
  }) async {
    final body = <String, dynamic>{'post_content_id': postContentId};

    if (title != null) body['title'] = title;
    if (content != null) body['content'] = content;
    if (attachments != null) body['attachments'] = attachments;
    if (dueDate != null) body['due_date'] = dueDate;
    if (maxScore != null) body['max_score'] = maxScore;
    if (isGroup != null) body['is_group'] = isGroup;

    // Build attachments array - always send (even if empty) to allow clearing
    final List<Map<String, String>>? attachmentsList = attachments?.map((a) {
                final map = {
                  'file_url': a['file_url']?.toString() ?? '',
                  'file_type': a['file_type']?.toString() ?? '',
                };
                if (a['original_name'] != null) {
                  map['original_name'] = a['original_name']?.toString() ?? '';
                }
                return map;
              })
              .where((a) => a['file_url']!.isNotEmpty)
              .toList();

    // Build the full request body
    final requestBody = <String, dynamic>{
      'post_content_id': postContentId,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (attachmentsList != null) 'attachments': attachmentsList,
      if (dueDate != null) 'due_date': dueDate,
      if (maxScore != null) 'max_score': maxScore,
      if (isGroup != null) 'is_group': isGroup,
    };

    debugPrint('📤 Update post body: $requestBody');

    // If postId is provided, use PUT /social-feed/post/:postId
    if (postId != null && postId > 0) {
      final res = await _apiClient.put<Map<String, dynamic>>(
        '/social-feed/post/$postId',
        data: requestBody,
      );
      return res.data!;
    }

    // Otherwise use PUT /social-feed/post with post_content_id in body
    final res = await _apiClient.put<Map<String, dynamic>>(
      '/social-feed/post',
      data: requestBody,
    );
    return res.data!;
  }

  /// SEARCH POSTS
  Future<List<PostModel>> searchPosts({
    int? sectionId,
    required String keyword,
    int limit = 50,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/social-feed/post/search',
      queryParameters: {
        if (sectionId != null) 'section_id': sectionId,
        'keyword': keyword,
        'limit': limit,
      },
    );

    appLog.debug('🔍 Search posts response: ${response.data.runtimeType}');

    final rawList =
        (response.data as Map<String, dynamic>)['data'] as List? ?? [];

    return rawList
        .map<PostModel>((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> uploadAttachments({
    required List<File> files,
  }) async {
    final res = await _apiClient.uploadMultipart(
      '/uploadFile/social-feed/fileattachment',
      files: files,
      fieldName: 'files',
    );

    final data = res.data;
    if (data == null) return [];

    if (data is Map && data['files'] is List) {
      return List<Map<String, dynamic>>.from(data['files']);
    }

    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }

    return [];
  }

  Future<void> deleteAttachmentBlob(String blobName) async {
    await _apiClient.delete(
      '/deleteFile/social-feed',
      data: {
        'fileNames': [blobName],
      },
    );
  }

  /// DELETE POST
  Future<void> deletePost({int? postId, int? postContentId}) async {
    // If postId is provided, use DELETE /social-feed/post/:postId
    if (postId != null && postId > 0) {
      await _apiClient.delete('/social-feed/post/$postId');
      return;
    }

    // Otherwise use DELETE /social-feed/post with body
    await _apiClient.delete(
      '/social-feed/post',
      data: {
        if (postId != null) 'post_id': postId,
        if (postContentId != null) 'post_content_id': postContentId,
      },
    );
  }

  Future<PostModel> getPostDetail(int postId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/social-feed/post/$postId',
    );

    final raw = response.data;

    if (raw == null) {
      throw Exception('No data');
    }

    if (raw.containsKey('data')) {
      return PostModel.fromJson(raw['data']);
    }

    return PostModel.fromJson(raw);
  }
}
