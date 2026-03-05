import 'package:LinkLian/core/utils/logger.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/api_client.dart';
import '../models/post_model.dart';
import 'dart:io';

class PostRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> createPost({
    int? sectionId,
    List<int>? sectionIds,
    String? title,
    String? content,
    String? postType,
    bool isAnonymous = false,
    List<Map<String, dynamic>>? attachments,
    String? dueDate,
    double? maxScore,
    bool? isGroup,
    List<Map<String, dynamic>>? groups,
  }) async {
    final Map<String, dynamic> data = {
      if (title != null && title.isNotEmpty) 'title': title,
      if (content != null && content.isNotEmpty) 'content': content,
      if (postType != null && postType.isNotEmpty) 'post_type': postType,
      'is_anonymous': isAnonymous,
    };

    if (attachments != null && attachments.isNotEmpty) {
      final validAttachments = attachments
          .where((a) =>
              a['file_url'] != null &&
              a['file_url'].toString().isNotEmpty &&
              a['file_type'] != null &&
              a['file_type'].toString().isNotEmpty)
          .map((a) => {
                'file_url': a['file_url'],
                'file_type': a['file_type'],
                if (a['original_name'] != null) 'original_name': a['original_name'],
              })
          .toList();
      if (validAttachments.isNotEmpty) data['attachments'] = validAttachments;
    }

    if (sectionIds != null && sectionIds.isNotEmpty) {
      data['section_ids'] = sectionIds;
    } else if (sectionId != null) {
      data['section_id'] = sectionId;
    }

    if (postType == 'assignment') {
      if (dueDate != null) data['due_date'] = dueDate;
      if (maxScore != null) data['max_score'] = maxScore;
      if (isGroup != null) data['is_group'] = isGroup;
      if (groups != null && groups.isNotEmpty) data['groups'] = groups;
    }

    debugPrint('📤 Creating post with data: $data');
    final response = await _apiClient.post<dynamic>('/social-feed/post', data: data);
    debugPrint('📥 Create post response: ${response.data}');

    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {'success': true, 'data': response.data};
  }

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
    final rawList = (response.data as Map<String, dynamic>)['data'] as List? ?? [];
    return rawList.map<PostModel>((e) => PostModel.fromJson(e as Map<String, dynamic>)).toList();
  }

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
    final List<Map<String, String>>? attachmentsList = attachments != null
        ? attachments
            .map((a) {
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
            .toList()
        : null;

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

    if (postId != null && postId > 0) {
      final res = await _apiClient.put<Map<String, dynamic>>('/social-feed/post/$postId', data: requestBody);
      return res.data!;
    }
    final res = await _apiClient.put<Map<String, dynamic>>('/social-feed/post', data: requestBody);
    return res.data!;
  }

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
    final rawList = (response.data as Map<String, dynamic>)['data'] as List? ?? [];
    return rawList.map<PostModel>((e) => PostModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> uploadAttachments({required List<File> files}) async {
    final res = await _apiClient.uploadMultipart(
      '/uploadFile/social-feed/fileattachment',
      files: files,
      fieldName: 'files',
    );
    final data = res.data;
    if (data == null) return [];
    if (data is Map && data['files'] is List) return List<Map<String, dynamic>>.from(data['files']);
    if (data is List) return List<Map<String, dynamic>>.from(data);
    return [];
  }

  Future<void> deleteAttachmentBlob(String blobName) async {
    await _apiClient.delete('/deleteFile/social-feed', data: {'fileNames': [blobName]});
  }

  Future<void> deletePost({int? postId, int? postContentId}) async {
    if (postId != null && postId > 0) {
      await _apiClient.delete('/social-feed/post/$postId');
      return;
    }
    await _apiClient.delete('/social-feed/post', data: {
      if (postId != null) 'post_id': postId,
      if (postContentId != null) 'post_content_id': postContentId,
    });
  }
}
