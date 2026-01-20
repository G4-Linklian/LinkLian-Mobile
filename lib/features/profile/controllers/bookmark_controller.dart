import 'package:get/get.dart';
import '../../auth/controller/auth_controller.dart';
import '../../../data/model/bookmark_model.dart';
import '../../../data/repository/bookmark_repository.dart';

enum BookmarkType { post, community }
enum SortType { all, newest, oldest }

class BookmarkController extends GetxController {
  final BookmarkRepository repo;
  BookmarkController(this.repo);

  final bookmarks = <BookmarkModel>[].obs;
  final loading = false.obs;

  final sortType = SortType.all.obs;
  final type = BookmarkType.post.obs;

  @override
  void onInit() {
    super.onInit();

    final auth = Get.find<AuthController>();

    ever<int?>(auth.userId, (userId) {
      if (userId != null) {
        _fetchBookmarks(userId);
      }
    });

    if (auth.userId.value != null) {
      _fetchBookmarks(auth.userId.value!);
    }
  }

  Future<void> _fetchBookmarks(int userId) async {
    try {
      loading.value = true;

      String? sortOrder;
      if (sortType.value == SortType.newest) {
        sortOrder = 'desc';
      } else if (sortType.value == SortType.oldest) {
        sortOrder = 'asc';
      }

      final result = await repo.getBookmarks(
        userId: userId,
        sortOrder: sortOrder,
      );

      bookmarks.value = result;
      print(bookmarks.map((e) => e.title).toList());
    } finally {
      loading.value = false;
    }
  }

  Future<void> removeBookmark(int postId) async {
    final auth = Get.find<AuthController>();
    final userId = auth.userId.value;
    if (userId == null) return;

    try {
      await repo.deleteBookmark(
        userId: userId,
        postId: postId,
      );

      bookmarks.removeWhere((b) => b.postId == postId);
    } catch (e) {
      Get.snackbar(
        'เกิดข้อผิดพลาด',
        'ไม่สามารถลบบุ๊กมาร์กได้',
      );
    }
  }

  void changeSort(SortType value) {
    sortType.value = value;

    final auth = Get.find<AuthController>();
    if (auth.userId.value != null) {
      _fetchBookmarks(auth.userId.value!);
    }
  }

  void changeType(BookmarkType value) {
    type.value = value;
  }
}
