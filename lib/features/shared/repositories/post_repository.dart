import 'dart:io';

import '../../../core/services/api_client.dart';
import '../../../core/utils/api_response_parser.dart';
import '../../../core/utils/logger.dart';
import '../models/post_model.dart';

class PostRepository {
  final ApiClient _apiClient = ApiClient();

  /// CREATE POST
  Future<PostModel?> createPost({
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

    appLog.info('[PostRepository] Creating post with data:', data: data);

    final response = await _apiClient.post<Map<String, dynamic>>(
      '/social-feed/post',
      data: data,
    );

    appLog.info('[PostRepository] Create post response:', data: response.data ?? 'No data');

    return ApiResponseParser.parseObject(
      response.data,
      PostModel.fromJson,
    );
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
    if (response.data is Map) {
      final data = (response.data as Map)['data'];
      appLog.debug('GET POST RESPONSE data count: ${data is List ? data.length : 'not a list'}');
      if (data is List) {
        for (final item in data) {
          if (item is Map) {
            appLog.debug('  post_id=${item['post_id']} user_sys_id=${item['user'] is Map ? (item['user'] as Map)['user_sys_id'] : item['user_sys_id']} is_anonymous=${item['is_anonymous']} is_user_deleted=${item['is_user_deleted']}');
          }
        }
      }
    }

    return ApiResponseParser.parseList(
      response.data,
      PostModel.fromJson,
    );
  }

  /// UPDATE POST
  Future<bool> updatePost({
    int? postId,
    required int postContentId,
    String? title,
    String? content,
    List<Map<String, dynamic>>? attachments,
    String? dueDate,
    double? maxScore,
    bool? isGroup,
    List<Map<String, dynamic>>? groups,
  }) async {
    final requestBody = <String, dynamic>{
      'post_content_id': postContentId,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (attachments != null) 'attachments': attachments,
      if (dueDate != null) 'due_date': dueDate,
      if (maxScore != null) 'max_score': maxScore,
      if (isGroup != null) 'is_group': isGroup,
      if (groups != null) 'groups': groups,
    };

    appLog.info('[PostRepository] Update post body:', data: requestBody);

    final res = postId != null && postId > 0
        ? await _apiClient.put<Map<String, dynamic>>(
            '/social-feed/post/$postId',
            data: requestBody,
          )
        : await _apiClient.put<Map<String, dynamic>>(
            '/social-feed/post',
            data: requestBody,
          );

    return ApiResponseParser.parseSuccess(res.data);
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

    appLog.debug('Search posts response:', data: response.data ?? 'No data');

    return ApiResponseParser.parseList(
      response.data,
      PostModel.fromJson,
    );
  }

  /// UPLOAD ATTACHMENTS
  /// Returns list of uploaded file info with keys: file_url, file_type, original_name
  /// no need to pass original_name, it will be extracted from the file if not provided
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

  /// DELETE ATTACHMENT
  Future<bool> deleteAttachmentBlob(String blobName) async {
    final res = await _apiClient.delete(
      '/deleteFile/social-feed',
      data: {
        'fileNames': [blobName],
      },
    );

    return ApiResponseParser.parseSuccess(res.data);
  }

  /// DELETE POST
  Future<bool> deletePost({int? postId, int? postContentId}) async {
    final res = postId != null && postId > 0
        ? await _apiClient.delete('/social-feed/post/$postId')
        : await _apiClient.delete(
            '/social-feed/post',
            data: {
              if (postId != null) 'post_id': postId,
              if (postContentId != null) 'post_content_id': postContentId,
            },
          );

    return ApiResponseParser.parseSuccess(res.data);
  }
}
