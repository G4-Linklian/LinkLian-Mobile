import 'package:LinkLian/data/repository/post_repository.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../auth/controller/auth_controller.dart';
import '../../../data/model/comment_model.dart';
import '../../../data/model/post_model.dart';
import '../../../data/repository/comment_repository.dart';
import '../../../core/utils/dialog_helper.dart';

class CommentController extends GetxController {
  final CommentRepository _repo = CommentRepository();

  // ===== post / user =====
  late final int postId;
  // late final PostModel post;
  PostModel? post;
  late final int userSysId;

  // ===== input =====
  final textController = TextEditingController();
  final focusNode = FocusNode();
  final replyingTo = Rx<CommentModel?>(null);
  final isAnonymous = false.obs;

  // ===== pagination =====
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  int offset = 0;
  bool hasMore = true;
  final int pageSize = 10;

  // ===== comment storage =====
  final rootComments = <CommentModel>[].obs;
  final flatComments = <CommentModel>[].obs;
  final visibleChildrenCount = <int, int>{}.obs;
  final int replyPageSize = 5;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    final auth = Get.find<AuthController>();
    if (auth.userId.value == null) {
      DialogHelper.showErrorDialog(description: 'ไม่พบข้อมูลผู้ใช้');
      return;
    }

    userSysId = auth.userId.value!;

    final args = Get.arguments;
    postId = args['postId'];

    if (args['post'] != null) {
      post = args['post'] as PostModel;
    } else {
      await _loadPostFromServer(postId);
    }

    await loadComments();
  }

  @override
  void onClose() {
    textController.dispose();
    focusNode.dispose();
    super.onClose();
  }

  // LOAD COMMENTS

  Future<void> loadComments({bool loadMore = false}) async {
    if (loadMore) {
      if (isLoadingMore.value || !hasMore) return;
      isLoadingMore.value = true;
    } else {
      if (isLoading.value) return;
      isLoading.value = true;
    }

    try {
      final res = await _repo.getComments(
        postId: postId,
        offset: offset,
        limit: pageSize,
      );

      for (final comment in res.comments) {
        rootComments.add(comment);
        visibleChildrenCount[comment.commentId] = 0;
      }

      _rebuildFlatList();

      offset += res.comments.length;
      hasMore = res.hasMore;
    } catch (e) {
      DialogHelper.showErrorDialog(description: 'ไม่สามารถโหลดความคิดเห็นได้');
    } finally {
      if (loadMore) {
        isLoadingMore.value = false;
      } else {
        isLoading.value = false;
      }
    }
  }

  // REFRESH COMMENTS
  Future<void> refreshComments() async {
    offset = 0;
    hasMore = true;
    rootComments.clear();
    flatComments.clear();
    visibleChildrenCount.clear();

    await loadComments();
  }

  Future<void> _loadPostFromServer(int id) async {
    try {
      final repo = PostRepository();
      final result = await repo.getPostDetail(id);

      post = result;
    } catch (e, stack) {
      debugPrint('POST DETAIL ERROR: $e');
      debugPrintStack(stackTrace: stack);

      DialogHelper.showErrorDialog(description: 'โหลดโพสต์ล้มเหลว');
    }
  }

  // FLATTEN COMMENTS

  void _rebuildFlatList() {
    final List<CommentModel> flat = [];

    for (final root in rootComments) {
      _appendComment(comment: root, flat: flat);
    }

    flatComments.assignAll(flat);
  }

  void _appendComment({
    required CommentModel comment,
    required List<CommentModel> flat,
  }) {
    flat.add(comment);

    final visible = visibleChildrenCount[comment.commentId] ?? 0;
    if (visible <= 0) return;

    for (int i = 0; i < visible && i < comment.children.length; i++) {
      _appendComment(comment: comment.children[i], flat: flat);
    }
  }

  void _expandThreadForParent(int parentId) {
    for (final root in rootComments) {
      if (_expandRecursive(root, parentId)) {
        break;
      }
    }

    _rebuildFlatList();
  }

  bool _expandRecursive(CommentModel comment, int targetId) {
    if (comment.commentId == targetId) {
      visibleChildrenCount[targetId] = comment.childrenCount;
      return true;
    }

    for (final child in comment.children) {
      if (_expandRecursive(child, targetId)) {
        visibleChildrenCount[comment.commentId] =
            (visibleChildrenCount[comment.commentId] ?? 0) + 1;
        return true;
      }
    }

    return false;
  }

  // TOGGLE / LOAD MORE REPLIES

  void toggleReplies(CommentModel parent) {
    final id = parent.commentId;
    final total = parent.childrenCount;
    final current = visibleChildrenCount[id] ?? 0;

    final nextVisible = (current + replyPageSize).clamp(0, total);
    visibleChildrenCount[id] = nextVisible;

    _rebuildFlatList();
  }

  // CREATE COMMENT / REPLY

  Future<void> submitComment(String text) async {
    if (text.trim().isEmpty) return;

    final parent = replyingTo.value;
    final parentId = parent?.commentId;

    // Clear input immediately for better UX
    textController.clear();
    replyingTo.value = null;

    try {
      await _repo.createComment(
        postId: postId,
        userId: userSysId,
        text: text,
        isAnonymous: isAnonymous.value,
        parentId: parentId,
      );

      // Refresh comments from server to get the new comment with correct data
      await _refreshComments();

      // Expand the parent thread if this was a reply
      if (parentId != null) {
        _expandThreadForParent(parentId);
      }

      DialogHelper.showNotification(
        title: 'สำเร็จ',
        message: 'ส่งความคิดเห็นเรียบร้อย',
        type: NotificationType.success,
      );
    } catch (e) {
      DialogHelper.showErrorDialog(description: 'ไม่สามารถส่งความคิดเห็นได้');
    }
  }

  /// Refresh all comments from server
  Future<void> _refreshComments() async {
    try {
      final res = await _repo.getComments(
        postId: postId,
        limit: 100, // Get all comments
      );

      // Save current visibility state
      final Map<int, int> oldVisibility = Map.from(visibleChildrenCount);

      rootComments.clear();
      visibleChildrenCount.clear();

      for (final comment in res.comments) {
        rootComments.add(comment);
        // Restore previous visibility or default to 0 (collapsed)
        visibleChildrenCount[comment.commentId] =
            oldVisibility[comment.commentId] ?? 0;
        _restoreChildrenVisibility(comment, oldVisibility);
      }

      _rebuildFlatList();
    } catch (e) {
      debugPrint('Refresh comments error: $e');
    }
  }

  /// Recursively restore children visibility from old state
  void _restoreChildrenVisibility(
    CommentModel comment,
    Map<int, int> oldVisibility,
  ) {
    for (final child in comment.children) {
      visibleChildrenCount[child.commentId] =
          oldVisibility[child.commentId] ?? 0;
      _restoreChildrenVisibility(child, oldVisibility);
    }
  }
}
