import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../auth/controller/auth_controller.dart';
import '../../../data/model/comment_model.dart';
import '../../../data/model/post_model.dart';
import '../../../data/repository/comment_repository.dart';
import '../../../core/utils/dialog_helper.dart';

class CommentController extends GetxController {
  final CommentRepository _repo = CommentRepository();

  // ===== post / user =====
  late final int postId;
  late final PostModel post;
  late final int userSysId;

  // ===== input =====
  final textController = TextEditingController();
  final focusNode = FocusNode();
  final replyingTo = Rx<CommentModel?>(null);
  final isAnonymous = false.obs;

  // ===== pagination =====
  final isLoading = false.obs;
  int? nextCursor;
  bool hasMore = true;
  int? _lastRepliedParentId;

  // ===== comment storage =====
  final rootComments = <CommentModel>[].obs;
  final flatComments = <CommentModel>[].obs;
  final visibleChildrenCount = <int, int>{}.obs;
  final int replyPageSize = 5;

  @override
  void onInit() {
    super.onInit();

    final auth = Get.find<AuthController>();
    if (auth.userId.value == null) {
      DialogHelper.showErrorDialog(description: 'ไม่พบข้อมูลผู้ใช้');
      return;
    }

    userSysId = auth.userId.value!;
    final args = Get.arguments;
    post = args['post'] as PostModel;
    postId = args['postId'];

    loadComments();
  }

  @override
  void onClose() {
    textController.dispose();
    focusNode.dispose();
    super.onClose();
  }

  // LOAD COMMENTS

  Future<void> loadComments() async {
    if (isLoading.value || !hasMore) return;

    isLoading.value = true;

    try {
      final res = await _repo.getComments(
        postId: postId,
        nextCursor: nextCursor,
        limit: 10,
      );

      for (final comment in res.comments) {
  rootComments.add(comment);

  visibleChildrenCount[comment.commentId] = 0;
}

      _rebuildFlatList();

if (_lastRepliedParentId != null) {
  _expandThreadForParent(_lastRepliedParentId!);
  _lastRepliedParentId = null;
}

      nextCursor = res.nextCursor;
      hasMore = res.hasMore;
    } catch (e) {
      DialogHelper.showErrorDialog(description: 'ไม่สามารถโหลดความคิดเห็นได้');
    } finally {
      isLoading.value = false;
    }
  }

  // FLATTEN COMMENTS 

void _rebuildFlatList() {
  final List<CommentModel> flat = [];

  for (final root in rootComments) {
    _appendComment(
      comment: root,
      flat: flat,
    );
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

  for (int i = 0;
      i < visible && i < comment.children.length;
      i++) {
    _appendComment(
      comment: comment.children[i],
      flat: flat,
    );
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
_lastRepliedParentId = parent?.commentId;

textController.clear();
replyingTo.value = null;

    try {
      await _repo.createComment(
        postId: postId,
        userId: userSysId,
        text: text,
        isAnonymous: isAnonymous.value,
        parentId: parent?.commentId,
      );

      // ===== FULL REFRESH =====
      rootComments.clear();
      flatComments.clear();
      visibleChildrenCount.clear();
      nextCursor = null;
      hasMore = true;

      await loadComments();

      DialogHelper.showNotification(
        title: 'สำเร็จ',
        message: 'ส่งความคิดเห็นเรียบร้อย',
        type: NotificationType.success,
      );
    } catch (e) {
      DialogHelper.showErrorDialog(description: 'ไม่สามารถส่งความคิดเห็นได้');
    }
  }
}