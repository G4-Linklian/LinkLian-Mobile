import 'package:LinkLian/core/utils/logger.dart';
import 'package:LinkLian/features/community/data/models/community_post_model.dart';
import 'package:LinkLian/features/community/data/repositories/community_bookmark_repository.dart';
import 'package:get/get.dart';
import '../../auth/controller/auth_controller.dart';
import '../../classes/data/models/bookmark_model.dart';
import '../repositories/bookmark_repository.dart';
import '../../../core/utils/dialog_helper.dart';

enum BookmarkType { post, community }

enum SortType { all, newest, oldest }

class BookmarkController extends GetxController {
  final BookmarkRepository repo;
  BookmarkController(this.repo);
  final communityBookmarks = <CommunityPostModel>[].obs;

  final CommunityBookmarkRepository communityRepo =
      CommunityBookmarkRepository();

  final bookmarks = <BookmarkModel>[].obs;
  final isToggling = false.obs;
  final bookmarkedPostIds = <int>{}.obs;

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
      } else {
        bookmarks.clear();
        bookmarkedPostIds.clear();
      }
    });

    if (auth.userId.value != null) {
      _fetchBookmarks(auth.userId.value!);
    }
  }


  Future<void> _fetchBookmarks(int userId) async {
    try {
      loading.value = true;

      final result = await repo.getBookmarks(userId: userId);

      bookmarks.assignAll(result);
      sortPostBookmarks();

      /// Update bookmarkedPostIds
      bookmarkedPostIds
        ..clear()
        ..addAll(result.map((b) => b.postId));
    } catch (e) {
      appLog.info('❌ Error fetching bookmarks: $e');
      DialogHelper.showNotification(
        title: 'เกิดข้อผิดพลาด',
        message: 'ไม่สามารถโหลดบุ๊กมาร์กได้',
        type: NotificationType.error,
      );
    } finally {
      loading.value = false;
    }
  }

  bool isBookmarked(int postId) {
    return bookmarkedPostIds.contains(postId);
  }

  Future<void> toggleBookmark({
    required int postId,
    required int postContentId,
  }) async {
    final auth = Get.find<AuthController>();
    final userId = auth.userId.value;

    if (userId == null) {
      DialogHelper.showNotification(
        title: 'เตือน',
        message: 'กรุณาเข้าสู่ระบบก่อน',
        type: NotificationType.warning,
      );
      return;
    }

    final wasBookmarked = isBookmarked(postId);

    try {
      if (wasBookmarked) {
        bookmarkedPostIds.remove(postId);
        bookmarks.removeWhere((b) => b.postId == postId);
      } else {
        bookmarkedPostIds.add(postId);
      }

      // เรียก API
      final success = await repo.toggleBookmark(userId: userId, postId: postId);

      if (!success) throw Exception('Toggle bookmark failed');

      if (!wasBookmarked) {
        // สร้าง bookmark สำเร็จ
        appLog.info('✅ Bookmark created for post $postId');
        DialogHelper.showNotification(
          title: 'สำเร็จ',
          message: 'บันทึกโพสต์เรียบร้อยแล้ว',
          type: NotificationType.success,
        );
        // Refresh bookmark list เพื่อได้ข้อมูลทั้งหมด
        await _fetchBookmarks(userId);
      } else {
        // ลบ bookmark สำเร็จ
        appLog.info('✅ Bookmark removed for post $postId');
        DialogHelper.showNotification(
          title: 'สำเร็จ',
          message: 'ลบบุ๊กมาร์กเรียบร้อยแล้ว',
          type: NotificationType.success,
        );
      }
    } catch (e) {
      appLog.info('❌ Error toggling bookmark: $e');

      if (wasBookmarked) {
        bookmarkedPostIds.add(postId);
      } else {
        bookmarkedPostIds.remove(postId);
      }

      DialogHelper.showNotification(
        title: 'เกิดข้อผิดพลาด',
        message: 'ไม่สามารถบันทึกบุ๊กมาร์กได้',
        type: NotificationType.error,
      );
    }
  }

  Future<void> removeBookmark(int postId) async {
    final auth = Get.find<AuthController>();
    final userId = auth.userId.value;

    if (userId == null) return;

    try {
      // Optimistic update
      bookmarks.removeWhere((b) => b.postId == postId);
      bookmarkedPostIds.remove(postId);

      await repo.deleteBookmark(userId: userId, postId: postId);

      appLog.info('✅ Bookmark removed for post $postId');
      DialogHelper.showNotification(
        title: 'สำเร็จ',
        message: 'ลบบุ๊กมาร์กเรียบร้อยแล้ว',
        type: NotificationType.success,
      );
    } catch (e) {
      appLog.info('❌ Error removing bookmark: $e');

      // Rollback
      await _fetchBookmarks(userId);

      DialogHelper.showNotification(
        title: 'เกิดข้อผิดพลาด',
        message: 'ไม่สามารถลบบุ๊กมาร์กได้',
        type: NotificationType.error,
      );
    }
  }

  Future<void> loadCommunityBookmarks() async {
    final auth = Get.find<AuthController>();
    final userId = auth.userId.value;

    if (userId == null) return;

    try {
      loading.value = true;

      final result = await communityRepo.getMyBookmarks();

      communityBookmarks.assignAll(result);
      sortCommunityBookmarks();

      appLog.info("[Bookmark]Loaded ${result.length} community bookmarks");
    } catch (e) {
      appLog.info("[Bookmark]Error loading community bookmarks: $e");
    } finally {
      loading.value = false;
    }
  }
  Future<void> toggleCommunityBookmark(int postId) async {
  if (isToggling.value) return; 

  try {
    isToggling.value = true;

    final result =
        await communityRepo.toggleBookmark(postId: postId);

    final action = result['action'];

    if (action == 'created') {
      DialogHelper.showNotification(
        title: 'สำเร็จ',
        message: 'บันทึกโพสต์เรียบร้อยแล้ว',
        type: NotificationType.success,
      );
    } else if (action == 'removed') {
      DialogHelper.showNotification(
        title: 'สำเร็จ',
        message: 'ลบบุ๊กมาร์กเรียบร้อยแล้ว',
        type: NotificationType.success,
      );
    }

    await loadCommunityBookmarks();

  } catch (e) {
    DialogHelper.showNotification(
      title: 'เกิดข้อผิดพลาด',
      message: 'ไม่สามารถทำรายการได้',
      type: NotificationType.error,
    );
  } finally {
    isToggling.value = false;
  }
}

  void changeSort(SortType value) {
    sortType.value = value;

    if (type.value == BookmarkType.post) {
      sortPostBookmarks();
    } else {
      sortCommunityBookmarks();
    }
  }

  void changeType(BookmarkType value) {
    type.value = value;

    final auth = Get.find<AuthController>();

    if (auth.userId.value == null) return;

    if (value == BookmarkType.post) {
      _fetchBookmarks(auth.userId.value!);
    } else {
      loadCommunityBookmarks();
    }
  }

  void sortCommunityBookmarks() {
    if (sortType.value == SortType.all) {
      return;
    }

    final sorted = [...communityBookmarks];

    if (sortType.value == SortType.newest) {
      sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (sortType.value == SortType.oldest) {
      sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    communityBookmarks.assignAll(sorted);
  }

  void sortPostBookmarks() {
    final sorted = [...bookmarks];

    if (sortType.value == SortType.newest) {
      sorted.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    } else if (sortType.value == SortType.oldest) {
      sorted.sort((a, b) => a.savedAt.compareTo(b.savedAt));
    }

    bookmarks.assignAll(sorted);
  }

  @override
  void onClose() {
    bookmarkedPostIds.clear();
    super.onClose();
  }
}
