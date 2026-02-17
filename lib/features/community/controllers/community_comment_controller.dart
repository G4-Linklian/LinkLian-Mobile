import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/model/community_comment_model.dart';
import '../../../data/repository/community_comment_repository.dart';
import '../../../core/utils/dialog_helper.dart';

class CommunityCommentController extends GetxController {
  final CommunityCommentRepository _repo = CommunityCommentRepository();

  // ===== POST =====
  late final int postCommuId;
  late final Widget postCardWidget;

  // ===== USER =====
  late final int userSysId;

  // ===== INPUT =====
  final textController = TextEditingController();
  final focusNode = FocusNode();
  final replyingTo = Rx<CommunityCommentModel?>(null);

  // ===== LOADING =====
  final isLoading = false.obs;
  final isLoadingMore = false.obs;

  // ===== PAGINATION =====
  int offset = 0;
  final int pageSize = 10;
  bool hasMore = true;

  // ===== STORAGE =====
  final rootComments = <CommunityCommentModel>[].obs;
  final flatComments = <CommunityCommentModel>[].obs;

  final visibleChildrenCount = <int, int>{}.obs;
  final int replyPageSize = 5;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;

    postCommuId = args['postCommuId'];
    postCardWidget = args['postCardWidget'];
    userSysId = args['userSysId'];

    loadComments();
  }

  @override
  void onClose() {
    textController.dispose();
    focusNode.dispose();
    super.onClose();
  }

  Future<void> loadComments({bool loadMore = false}) async {
    if (loadMore) {
      if (isLoadingMore.value || !hasMore) return;
      isLoadingMore.value = true;
    } else {
      if (isLoading.value) return;
      isLoading.value = true;
      rootComments.clear();
      flatComments.clear();
      visibleChildrenCount.clear();
      offset = 0;
    }

    try {
      final result = await _repo.getComments(
        postCommuId: postCommuId,
        limit: pageSize,
        offset: offset,
      );

      final comments = result.comments;
      final more = result.hasMore;

      for (final comment in comments) {
        rootComments.add(comment);
        visibleChildrenCount[comment.commentId] = 0;
      }

      _rebuildFlatList();

      offset += comments.length;
      hasMore = more;
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

  Future<void> refreshComments() async {
    hasMore = true;
    await loadComments(loadMore: false);
  }

  void _rebuildFlatList() {
    final List<CommunityCommentModel> flat = [];

    for (final root in rootComments) {
      _appendComment(root, flat);
    }

    flatComments.assignAll(flat);
  }

  void _appendComment(
    CommunityCommentModel comment,
    List<CommunityCommentModel> flat,
  ) {
    flat.add(comment);

    final visible = visibleChildrenCount[comment.commentId] ?? 0;

    if (visible <= 0) return;

    for (int i = 0; i < visible && i < comment.children.length; i++) {
      _appendComment(comment.children[i], flat);
    }
  }

  void toggleReplies(CommunityCommentModel parent) {
    final id = parent.commentId;
    final total = parent.childrenCount;
    final current = visibleChildrenCount[id] ?? 0;

    final nextVisible = (current + replyPageSize).clamp(0, total);

    visibleChildrenCount[id] = nextVisible;

    _rebuildFlatList();
  }

  Future<void> submitComment(String text) async {
    if (text.trim().isEmpty) return;

    final parent = replyingTo.value;
    final parentId = parent?.commentId;

    textController.clear();
    replyingTo.value = null;

    try {
      final int newCommentId = await _repo.createComment(
        postCommuId: postCommuId,
        userId: userSysId,
        text: text,
        parentId: parentId,
      );

      await refreshComments();

      if (parentId != null) {
        _expandThread(parentId);
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

  Future<void> deleteComment(int commentId) async {
    try {
      await _repo.deleteComment(userId: userSysId, commentId: commentId);

      await refreshComments();

      DialogHelper.showNotification(
        title: 'ลบสำเร็จ',
        message: 'ความคิดเห็นถูกลบแล้ว',
        type: NotificationType.success,
      );
    } catch (e) {
      DialogHelper.showErrorDialog(description: 'ไม่สามารถลบความคิดเห็นได้');
    }
  }

  void _expandThread(int parentId) {
    for (final root in rootComments) {
      if (_expandRecursive(root, parentId)) break;
    }
    _rebuildFlatList();
  }

  bool _expandAllParents(CommunityCommentModel comment, int targetId) {
    if (comment.commentId == targetId) {
      visibleChildrenCount[targetId] = comment.children.length;
      return true;
    }

    for (final child in comment.children) {
      if (_expandAllParents(child, targetId)) {
        visibleChildrenCount[comment.commentId] = comment.children.length;
        return true;
      }
    }
    return false;
  }

  bool _expandRecursive(CommunityCommentModel comment, int targetId) {
    if (comment.commentId == targetId) {
      visibleChildrenCount[targetId] = comment.children.length;
      return true;
    }

    for (final child in comment.children) {
      if (_expandRecursive(child, targetId)) {
        visibleChildrenCount[comment.commentId] = comment.children.length;
        return true;
      }
    }

    return false;
  }

  int calculateDepth(CommunityCommentModel comment) {
    int depth = 0;
    CommunityCommentModel? current = comment;

    while (current?.parentId != null) {
      depth++;
      current = flatComments.firstWhereOrNull(
        (c) => c.commentId == current!.parentId,
      );
      if (current == null) break;
    }

    return depth;
  }

  bool hasNextSibling(List<CommunityCommentModel> flat, int index, int depth) {
    for (int i = index + 1; i < flat.length; i++) {
      final d = calculateDepth(flat[i]);
      if (d == depth) return true;
      if (d < depth) return false;
    }
    return false;
  }
}
