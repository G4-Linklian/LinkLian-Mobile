import '../model/bookmark_model.dart';
import '../../core/services/api_client.dart';

class BookmarkRepository {
  final ApiClient api;
  BookmarkRepository(this.api);

  /// ดึงรายการ bookmark ของ user
  Future<List<BookmarkModel>> getBookmarks({
    required int userId,
    String? sortOrder,
  }) async {
    final Map<String, dynamic> body = {
      'user_sys_id': userId,
      'flag_valid': true,
    };

    if (sortOrder != null) {
      body['sort_by'] = 'saved_at';
      body['sort_order'] = sortOrder;
    }

    final res = await api.post(
      '/bookmark.get',
      data: body,
    );

    final List list = res.data['data'] ?? [];
    return list.map((e) => BookmarkModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> createBookmark({
    required int userId,
    required int postId,
  }) async {
    final res = await api.post(
      '/bookmark.create',
      data: {
        'user_sys_id': userId,
        'post_id': postId,
      },
    );

    if (res.data['success'] == true) {
      return {
        'success': true,
        'message': res.data['message'],
        'data': res.data['data'],
      };
    }

    throw Exception(res.data['message'] ?? 'Failed to create bookmark');
  }

  /// ลบ bookmark
  Future<void> deleteBookmark({
    required int userId,
    required int postId,
  }) async {
    final res = await api.post(
      '/bookmark.delete',
      data: {
        'user_sys_id': userId,
        'post_id': postId,
      },
    );

    if (res.data['success'] != true) {
      throw Exception(res.data['message'] ?? 'Failed to delete bookmark');
    }
  }

  /// ตรวจสอบว่า post ถูก bookmark หรือไม่
  Future<bool> isBookmarked({
    required int userId,
    required int postId,
  }) async {
    try {
      final res = await api.post(
        '/bookmark.get',
        data: {
          'user_sys_id': userId,
          'post_id': postId,
          'flag_valid': true,
        },
      );

      final List list = res.data['data'] ?? [];
      return list.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}