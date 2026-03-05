import 'package:get/get.dart';
import '../../auth/controller/auth_controller.dart';
import '../../classes/data/models/bookmark_model.dart';
import '../../shared/repositories/bookmark_repository.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/utils/logger.dart';

enum BookmarkType { post, community }

enum SortType { all, newest, oldest }

class BookmarkController extends GetxController {
  final BookmarkRepository repo;
  BookmarkController(this.repo);

  // เก็บ bookmark ทั้งหมด (แสดงใน BookmarkSwitcher)
  final bookmarks = <BookmarkModel>[].obs;

  final bookmarkedPostIds = <int>{}.obs;

  final loading = false.obs;
  final sortType = SortType.all.obs;
  final type = BookmarkType.post.obs;

  @override
  void onInit() {
    super.onInit();

    final auth = Get.find<AuthController>();

    // ตรวจสอบเมื่อ userId เปลี่ยน
    ever<int?>(auth.userId, (userId) {
      if (userId != null) {
        _fetchBookmarks(userId);
      } else {
        bookmarks.clear();
        bookmarkedPostIds.clear();
      }
    });

    // โหลด bookmark ครั้งแรก
    if (auth.userId.value != null) {
      _fetchBookmarks(auth.userId.value!);
    }
  }

  /// ดึงข้อมูล bookmark จาก backend
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

      bookmarks.assignAll(result);

      /// Update bookmarkedPostIds
      bookmarkedPostIds
        ..clear()
        ..addAll(result.map((b) => b.postId));

      print('✅ Loaded ${result.length} bookmarks');
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

  /// ใช้ใน CardPost - ตรวจสอบว่า post ถูก bookmark หรือไม่
  bool isBookmarked(int postId) {
    return bookmarkedPostIds.contains(postId);
  }

  /// Toggle bookmark (ใช้ใน CardPost)
  /// ถ้า bookmark อยู่ → ลบ
  /// ถ้าไม่ bookmark → สร้างใหม่
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
      // Optimistic update - อัปเดต UI ก่อน
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

  /// ลบ bookmark จาก BookmarkSwitcher
  Future<void> removeBookmark(int postId) async {
    final auth = Get.find<AuthController>();
    final userId = auth.userId.value;

    if (userId == null) return;

    try {
      // Optimistic update
      bookmarks.removeWhere((b) => b.postId == postId);
      bookmarkedPostIds.remove(postId);

      // เรียก API
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

  /// เปลี่ยนการเรียงลำดับ
  void changeSort(SortType value) {
    sortType.value = value;

    final auth = Get.find<AuthController>();
    if (auth.userId.value != null) {
      _fetchBookmarks(auth.userId.value!);
    }
  }

  /// เปลี่ยนประเภท bookmark
  void changeType(BookmarkType value) {
    type.value = value;
  }

  @override
  void onClose() {
    bookmarkedPostIds.clear();
    super.onClose();
  }
}
