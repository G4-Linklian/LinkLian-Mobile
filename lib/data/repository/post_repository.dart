import '../../core/services/api_client.dart';
import '../../data/model/post_model.dart';

class PostRepository {
  final ApiClient _apiClient = ApiClient();

  /// CREATE POST (student)
  Future<Map<String, dynamic>> createPost({
    required List<int> sectionIds,
    required String title,
    required String content,
    required String postType,
    required bool isAnonymous,
    List<Map<String, dynamic>>? attachments,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/post',
      data: {
        'section_ids': sectionIds,
        'title': title,
        'content': content,
        'post_type': postType,
        'is_anonymous': isAnonymous,
        'attachments': attachments,
      },
    );

    return response.data!;
  }

  /// GET POSTS IN CLASS
  Future<List<PostModel>> getPostInClass({
    required int sectionId,
    String? filterType,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/class',
      queryParameters: {
        'section_id': sectionId,
        if (filterType != null && filterType.isNotEmpty)
          'type': filterType,
      },
    );

    final List list = response.data?['data'] ?? [];

    return list
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// UPDATE POST
  Future<Map<String, dynamic>> updatePost({
    required int postContentId,
    required String title,
    required String content,
  }) async {
    final res = await _apiClient.put<Map<String, dynamic>>(
      '/post',
      data: {
        'post_content_id': postContentId,
        'title': title,
        'content': content,
      },
    );
    return res.data!;
  }

  /// DELETE POST
  Future<void> deletePost({
    required int postId,
    required int postContentId,
  }) async {
    await _apiClient.delete(
      '/post',
      data: {
        'post_id': postId,
        'post_content_id': postContentId,
      },
    );
  }
}