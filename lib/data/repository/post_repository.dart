import 'package:flutter/foundation.dart';
import '../../core/services/api_client.dart';
import '../../data/model/post_model.dart';

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
    final response = await _apiClient.get<List<dynamic>>(
      '/social-feed/post',
      queryParameters: {
        'section_id': sectionId,
        if (filterType != null && filterType.isNotEmpty) 'type': filterType,
        'offset': offset,
        'limit': limit,
      },
    );

    final list = response.data ?? [];

    return list
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// UPDATE POST (by post_content_id)
  Future<Map<String, dynamic>> updatePost({
    int? postId,
    int? postContentId,
    String? title,
    String? content,
    List<Map<String, dynamic>>? attachments,
  }) async {
    // Build attachments array - always send (even if empty) to allow clearing
    final List<Map<String, String>>? attachmentsList = attachments != null
        ? attachments.map((a) {
            final map = {
              'file_url': a['file_url']?.toString() ?? '',
              'file_type': a['file_type']?.toString() ?? '',
            };
            if (a['original_name'] != null) {
              map['original_name'] = a['original_name']?.toString() ?? '';
            }
            return map;
          }).where((a) => a['file_url']!.isNotEmpty).toList()
        : null;

    // If postId is provided, use PUT /social-feed/post/:postId
    if (postId != null && postId > 0) {
      final res = await _apiClient.put<Map<String, dynamic>>(
        '/social-feed/post/$postId',
        data: {
          if (title != null) 'title': title,
          if (content != null) 'content': content,
          if (attachments != null) 'attachments': attachmentsList,
        },
      );
      return res.data!;
    }

    // Otherwise use PUT /social-feed/post with post_content_id in body
    final res = await _apiClient.put<Map<String, dynamic>>(
      '/social-feed/post',
      data: {
        'post_content_id': postContentId,
        if (title != null) 'title': title,
        if (content != null) 'content': content,
        if (attachments != null) 'attachments': attachmentsList,
      },
    );
    return res.data!;
  }

  /// DELETE POST
  Future<void> deletePost({
    int? postId,
    int? postContentId,
  }) async {
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
}
