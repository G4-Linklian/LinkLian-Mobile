import '../model/bookmark_model.dart';
import '../../core/services/api_client.dart';

class BookmarkRepository {
  final ApiClient api;
  BookmarkRepository(this.api);

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

  final List list = res.data['data'];
  return list.map((e) => BookmarkModel.fromJson(e)).toList();
}
Future<void> deleteBookmark({
    required int userId,
    required int postId,
  }) async {
    await api.post(
      '/bookmark.delete',
      data: {
        'user_sys_id': userId,
        'post_id': postId,
      },
    );
  }
}
