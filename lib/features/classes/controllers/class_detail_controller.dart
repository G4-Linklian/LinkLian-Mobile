import 'package:get/get.dart';
import '../controllers/class_detail_filter.dart';
import '../../../data/repository/post_repository.dart';
import '../../../data/repository/class_feed_repository.dart';
import '../controllers/class_feed_controller.dart';
import '../../../data/model/post_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';

class ClassDetailController extends GetxController {
  final Rx<int?> sectionId = Rx<int?>(null);
  final Rx<String> subjectNameTh = Rx<String>('');
  final Rx<String> effectiveClassName = Rx<String>('');

  final Rx<ClassPostFilter> selectedFilter = ClassPostFilter.all.obs;
  final isLoading = false.obs;
  final RxList<PostModel> posts = <PostModel>[].obs;
  final RxSet<int> selectedPostIdsForAI = <int>{}.obs;

  final PostRepository _postRepository = PostRepository();
  final ClassFeedRepository _classFeedRepository = ClassFeedRepository();
  final ScrollController scrollController = ScrollController();

  List<int> get effectiveSectionIds {
    return [if (sectionId.value != null) sectionId.value!];
  }

  @override
  void onInit() {
    super.onInit();
    _initializeFromArguments();
  }

  void _initializeFromArguments() {
    final args = Get.arguments as Map<String, dynamic>?;

    if (args != null && args['sectionId'] != null) {
      sectionId.value = args['sectionId'] as int;

      // หา class detail จาก ClassFeedController
      fetchClassDetailFromFeed();

      // Fetch posts
      fetchPosts().then((_) {
        if (args['refresh'] == true) {
          scrollToTop();
        }
      });
    } else {
      Get.snackbar('เกิดข้อผิดพลาด', 'ข้อมูลไม่ครบถ้วน');
    }
  }

  /// FETCH CLASS DETAIL FROM FEED
  void fetchClassDetailFromFeed() {
    try {
      if (sectionId.value == null) return;

      if (!Get.isRegistered<ClassFeedController>()) {
        _fetchClassDetailFallback();
        return;
      }

      final feedController = Get.find<ClassFeedController>();

      final classDetail = feedController.classList.firstWhereOrNull(
        (c) => c.sectionId == sectionId.value,
      );

      if (classDetail != null) {
        subjectNameTh.value = classDetail.subjectNameTh;
        effectiveClassName.value = classDetail.effectiveClassName;
      } else {
        _fetchClassDetailFallback();
      }
    } catch (e) {
      _fetchClassDetailFallback();
    }
  }

  void removePostOptimistic(int postId) {
    posts.removeWhere((p) => p.postId == postId);
  }

  void updatePostOptimistic(PostModel updatedPost) {
    final index = posts.indexWhere(
      (p) => p.postContentId == updatedPost.postContentId,
    );

    if (index == -1) return;

    posts[index] = updatedPost;
    posts.refresh();
  }

  /// FETCH CLASS DETAIL FALLBACK
  Future<void> _fetchClassDetailFallback() async {
    try {
      if (sectionId.value == null) return;

      isLoading.value = true;

      final classDetail = await _classFeedRepository.getClassDetail(
        sectionId: sectionId.value!,
      );

      if (classDetail != null) {
        subjectNameTh.value = classDetail.subjectNameTh;
        effectiveClassName.value = classDetail.effectiveClassName;
      } else {
        //  Set default values
        subjectNameTh.value = 'ไม่ระบุ';
        effectiveClassName.value = 'ไม่ระบุ';
      }
    } catch (e) {
      subjectNameTh.value = 'ไม่ระบุ';
      effectiveClassName.value = 'ไม่ระบุ';
    } finally {
      isLoading.value = false;
    }
  }

  /// FETCH POSTS
  Future<void> fetchPosts({bool keepScroll = false}) async {
    double? savedOffset;

    if (keepScroll && scrollController.hasClients) {
      savedOffset = scrollController.offset;
    }

    try {
      // โหลดเฉพาะกรณีที่ไม่ keepScroll
      if (!keepScroll) {
        isLoading.value = true;
      }

      if (sectionId.value == null) {
        throw Exception('sectionId is null');
      }

      final result = await _postRepository.getPostInClass(
        sectionId: sectionId.value!,
        filterType: selectedFilter.value.apiValue,
      );

      posts.assignAll(result);
    } catch (e) {
      Get.snackbar('เกิดข้อผิดพลาด', 'ไม่สามารถโหลดโพสต์ได้');
    } finally {
      if (!keepScroll) {
        isLoading.value = false;
      }

      if (savedOffset != null && scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final offset = savedOffset!;
          final max = scrollController.position.maxScrollExtent;

          scrollController.jumpTo(offset > max ? max : offset);
        });
      }
    }
  }

  /// CHANGE FILTER
  void changeFilter(ClassPostFilter filter) {
    selectedFilter.value = filter;
    fetchPosts();
  }

  /// SELECT POST FOR AI
  void togglePostSelection(int postId) {
    if (selectedPostIdsForAI.contains(postId)) {
      selectedPostIdsForAI.remove(postId);
    } else {
      selectedPostIdsForAI.add(postId);
    }
  }

  /// GENERATE AI SUMMARY
  Future<void> generateAISummary() async {
    if (selectedPostIdsForAI.isEmpty) {
      Get.snackbar('แจ้งเตือน', 'กรุณาเลือกโพสต์อย่างน้อย 1 โพสต์');
      return;
    }

    try {
      Get.snackbar(
        'กำลังสรุป',
        'กำลังสรุปโพสต์ ${selectedPostIdsForAI.length} รายการ...',
      );
    } catch (e) {
      // print('❌ Error generating summary: $e');
      Get.snackbar('เกิดข้อผิดพลาด', 'ไม่สามารถสรุปเนื้อหาได้');
    }
  }

  void scrollToTop() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    scrollController.dispose();
    selectedPostIdsForAI.clear();
    super.onClose();
  }
}
